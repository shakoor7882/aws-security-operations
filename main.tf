terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.51.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  # Minimum of 2 availability zones are required by the ELB
  availability_zone_1 = "${var.aws_region}a"
  availability_zone_2 = "${var.aws_region}b"

  solution_workload = "wms"
  security_workload = "sec"
  fargate_workload  = "fargate"

  count_ec2_instance = var.workload_type == "INSTANCE" && var.enable_ec2 == true ? 1 : 0
  count_ec2_asg      = var.workload_type == "ASG" && var.enable_ec2 == true ? 1 : 0
  count_fargate      = var.enable_fargate == true ? 1 : 0
}

### General ###
resource "tls_private_key" "generated_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

### VPC ###
module "vpc_solution" {
  source              = "./modules/solutions/vpc"
  region              = var.aws_region
  workload            = local.solution_workload
  availability_zone_1 = local.availability_zone_1
  availability_zone_2 = local.availability_zone_2
}

module "vpc_security" {
  source            = "./modules/security/vpc"
  region            = var.aws_region
  workload          = local.security_workload
  availability_zone = local.availability_zone_1
}

module "vpc_peering" {
  source                    = "./modules/peering"
  security_requester_vpc_id = module.vpc_security.vpc_id
  solution_accepter_vpc_id  = module.vpc_solution.vpc_id

  security_requester_route_table_id = module.vpc_security.private_route_table_id
  security_requester_vpc_cidr_block = module.vpc_security.cidr_block

  solution_accepter_route_table_id = module.vpc_solution.private_route_table_id
  solution_accepter_vpc_cidr_block = module.vpc_solution.cidr_block
}

module "vpce_solution" {
  source    = "./common/vpce"
  workload  = local.solution_workload
  region    = var.aws_region
  vpc_id    = module.vpc_solution.vpc_id
  subnet_id = module.vpc_solution.vpce_subnet_id
}

module "vpce_security" {
  source    = "./common/vpce"
  workload  = local.security_workload
  region    = var.aws_region
  vpc_id    = module.vpc_security.vpc_id
  subnet_id = module.vpc_security.vpce_subnet_id
}

### S3 ###
module "s3_vpce_gateway" {
  source          = "./modules/solutions/s3/vpce-gateway"
  workload        = local.solution_workload
  vpc_id          = module.vpc_solution.vpc_id
  region          = var.aws_region
  route_table_ids = [module.vpc_solution.private_route_table_id]
}

module "s3_application" {
  source   = "./modules/solutions/s3/bucket-application"
  workload = local.solution_workload
}

module "s3_vpce_interface" {
  source    = "./modules/solutions/s3/vpce-interface"
  workload  = local.solution_workload
  region    = var.aws_region
  vpc_id    = module.vpc_solution.vpc_id
  subnet_id = module.vpc_solution.vpce_subnet_id
  bucket    = module.s3_application.bucket
}

# FIXME: Don't lock yourself out of the bucket
# module "s3_policy_application_vpce_interface" {
#   source    = "./modules/solutions/s3/bucket-application-vpce-policy"
#   bucket    = module.s3_application.bucket
#   bucket_id = module.s3_application.bucket_id
#   vpce_id   = module.s3_vpce_interface.vpce_id
# }

module "s3_attacker" {
  source   = "./modules/solutions/s3/bucket-attacker"
  workload = "attacker"
}

### Route 53 ###
module "route53" {
  source          = "./modules/route53"
  solution_vpc_id = module.vpc_solution.vpc_id
  security_vpc_id = module.vpc_security.vpc_id
}

### Systems Manager ###
module "ssm" {
  source              = "./modules/solutions/ssm"
  workload            = local.solution_workload
  private_key_openssh = tls_private_key.generated_key.private_key_openssh
}

### EC2 ###
module "wms_application_instance" {
  count                   = local.count_ec2_instance
  source                  = "./modules/solutions/ec2/instance"
  vpc_id                  = module.vpc_solution.vpc_id
  subnet                  = module.vpc_solution.private_subnet_id
  ami                     = var.ami
  instance_type           = var.instance_type
  public_key_openssh      = tls_private_key.generated_key.public_key_openssh
  route53_zone_id         = module.route53.zone_id
  security_vpc_cidr_block = module.vpc_security.cidr_block

  depends_on = [module.ssm, module.vpce_solution]
}

module "wms_application_asg" {
  count                   = local.count_ec2_asg
  source                  = "./modules/solutions/ec2/asg"
  workload                = local.solution_workload
  vpc_id                  = module.vpc_solution.vpc_id
  subnet                  = module.vpc_solution.private_subnet_id
  ami                     = var.ami
  instance_type           = var.instance_type
  public_key_openssh      = tls_private_key.generated_key.public_key_openssh
  route53_zone_id         = module.route53.zone_id
  security_vpc_cidr_block = module.vpc_security.cidr_block

  depends_on = [module.ssm, module.vpce_solution]
}

module "security_jumpserver" {
  source                  = "./modules/security/jumpserver"
  vpc_id                  = module.vpc_security.vpc_id
  subnet                  = module.vpc_security.private_subnet_id
  ami                     = var.ami
  instance_type           = var.instance_type
  route53_zone_id         = module.route53.zone_id
  solution_vpc_cidr_block = module.vpc_solution.cidr_block
}

### Fargate ###
module "fargate" {
  count                  = local.count_fargate
  source                 = "./modules/solutions/fargate"
  workload               = local.fargate_workload
  region                 = var.aws_region
  enable_fargate_service = var.enable_fargate_service
  vpc_id                 = module.vpc_solution.vpc_id
  elb_subnet_ids         = module.vpc_solution.public_subnet_ids
  ecs_subnet_ids         = [module.vpc_solution.private_subnet_id]
  ecs_task_cpu           = var.ecs_task_cpu
  ecs_task_memory        = var.ecs_task_memory
  vpce_subnet_id         = module.vpc_solution.vpce_subnet_id

  enable_waf                     = var.enable_waf
  waf_allowed_country_codes      = var.waf_allowed_country_codes
  waf_rate_limit                 = var.waf_rate_limit
  waf_rate_evaluation_window_sec = var.waf_rate_evaluation_window_sec
}

### Security ###
module "solution_isolated_security_group" {
  source   = "./modules/solutions/isolated-security-group"
  workload = local.solution_workload
  vpc_id   = module.vpc_solution.vpc_id
}

module "solution_forensics_security_group" {
  source                  = "./modules/solutions/forensics-security-group"
  workload                = local.solution_workload
  vpc_id                  = module.vpc_solution.vpc_id
  security_vpc_cidr_block = module.vpc_security.cidr_block
}

module "flowlogs_solution" {
  source   = "./common/flowlogs"
  workload = local.solution_workload
  vpc_id   = module.vpc_solution.vpc_id
}

module "flowlogs_security" {
  source   = "./common/flowlogs"
  workload = local.security_workload
  vpc_id   = module.vpc_security.vpc_id
}

module "route53_dns_firewall" {
  source          = "./modules/security/dns-firewall"
  vpc_id          = module.vpc_solution.vpc_id
  blocked_domains = var.route53_dns_firewall_blocked_domains
}

module "guardduty" {
  source                    = "./modules/security/guardduty"
  enable_guardduty          = var.enable_guardduty
  enable_runtime_monitoring = var.enable_guardduty_runtime_monitoring
}

module "sns" {
  source = "./modules/security/sns"
  email  = var.sns_email
}

module "eventbridge" {
  source        = "./modules/security/eventbridge"
  sns_topic_arn = module.sns.arn
}
