terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.48.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  solution_workload = "wms"
  security_workload = "sec"
  availability_zone = "${var.aws_region}a"
}

### General ###
resource "tls_private_key" "generated_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

### VPC ###
module "vpc_solution" {
  source            = "./modules/solution/vpc"
  region            = var.aws_region
  workload          = local.solution_workload
  availability_zone = local.availability_zone
}

module "vpc_security" {
  source            = "./modules/security/vpc"
  region            = var.aws_region
  workload          = local.security_workload
  availability_zone = local.availability_zone
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
module "s3_vpce" {
  source          = "./modules/solution/s3/vpce"
  vpc_id          = module.vpc_solution.vpc_id
  region          = var.aws_region
  route_table_ids = [module.vpc_solution.private_route_table_id]
}

module "s3_application" {
  source   = "./modules/solution/s3/bucket-application"
  workload = local.solution_workload
}

module "s3_attacker" {
  source   = "./modules/solution/s3/bucket-attacker"
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
  source              = "./modules/solution/ssm"
  workload            = local.solution_workload
  private_key_openssh = tls_private_key.generated_key.private_key_openssh
}

### EC2 ###

module "wms_application_instance" {
  count                   = var.workload_type == "EC2" ? 1 : 0
  source                  = "./modules/solution/ec2"
  vpc_id                  = module.vpc_solution.vpc_id
  subnet                  = module.vpc_solution.private_subnet_id
  ami                     = var.ami
  instance_type           = var.instance_type
  user_data               = var.user_data
  public_key_openssh      = tls_private_key.generated_key.public_key_openssh
  route53_zone_id         = module.route53.zone_id
  security_vpc_cidr_block = module.vpc_security.cidr_block

  depends_on = [module.ssm, module.vpce_solution]
}

module "wms_application_asg" {
  count                   = var.workload_type == "ASG" ? 1 : 0
  source                  = "./modules/solution/asg"
  workload                = local.solution_workload
  vpc_id                  = module.vpc_solution.vpc_id
  subnet                  = module.vpc_solution.private_subnet_id
  ami                     = var.ami
  instance_type           = var.instance_type
  user_data               = var.user_data
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
  user_data               = var.user_data
  route53_zone_id         = module.route53.zone_id
  solution_vpc_cidr_block = module.vpc_solution.cidr_block
}

### Fargate ###
module "elb" {
  source   = "./modules/elb"
  workload = local.workload
  subnets  = module.vpc.elb_subnets
  vpc_id   = module.vpc.vpc_id
}

module "iam" {
  source   = "./modules/iam"
  workload = local.workload
}

module "ecr" {
  source   = "./modules/ecr"
  workload = local.workload
}

module "ecs" {
  source                      = "./modules/ecs"
  workload                    = local.workload
  subnets                     = module.vpc.application_subnets
  vpc_id                      = module.vpc.vpc_id
  aws_region                  = var.aws_region
  ecr_repository_url          = module.ecr.repository_url
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.iam.ecs_task_role_arn
  primary_redis_endpoint      = module.redis.primary_redis_endpoint
  redis_port                  = module.redis.redis_port
  redis_auth_token            = var.redis_auth_token
  target_group_arn            = module.elb.target_group_arn
  task_cpu                    = var.ecs_task_cpu
  task_memory                 = var.ecs_task_memory
}

### Security ###
module "solution_isolated_security_group" {
  source   = "./modules/solution/isolated-security-group"
  workload = local.solution_workload
  vpc_id   = module.vpc_solution.vpc_id
}

module "solution_forensics_security_group" {
  source                  = "./modules/solution/forensics-security-group"
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
