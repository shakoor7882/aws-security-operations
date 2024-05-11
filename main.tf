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

# module "vpc_peering" {
#   source                    = "./modules/peering"
#   security_requester_vpc_id = module.vpc_security.vpc_id
#   solution_accepter_vpc_id  = module.vpc_solution.vpc_id

#   security_requester_route_table_id = module.vpc_security.private_route_table_id
#   security_requester_vpc_cidr_block = module.vpc_security.cidr_block

#   solution_accepter_route_table_id = module.vpc_solution.private_route_table_id
#   solution_accepter_vpc_cidr_block = module.vpc_solution.cidr_block
# }

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
module "wms_application" {
  source             = "./modules/solution/ec2"
  vpc_id             = module.vpc_solution.vpc_id
  subnet             = module.vpc_solution.private_subnet_id
  ami                = var.ami
  instance_type      = var.instance_type
  user_data          = var.user_data
  public_key_openssh = tls_private_key.generated_key.public_key_openssh
  route53_zone_id    = module.route53.zone_id

  depends_on = [module.ssm, module.vpce_solution]
}

module "security_jumpserver" {
  source          = "./modules/security/jumpserver"
  vpc_id          = module.vpc_security.vpc_id
  subnet          = module.vpc_security.private_subnet_id
  ami             = var.ami
  instance_type   = var.instance_type
  user_data       = var.user_data
  route53_zone_id = module.route53.zone_id
}
















### Security ###

# module "guardduty" {
#   source                    = "./modules/security/guardduty"
#   enable_guardduty          = var.enable_guardduty
#   enable_runtime_monitoring = var.enable_guardduty_runtime_monitoring
# }

# module "vpce_security" {
#   source    = "./modules/security/vpce"
#   region    = var.aws_region
#   vpc_id    = module.vpc.vpc_id
#   subnet_id = module.vpc.vpce_workload_subnet_id
# }

# module "sns" {
#   source = "./modules/security/sns"
#   email  = var.sns_email
# }

# module "eventbridge" {
#   source        = "./modules/security/eventbridge"
#   sns_topic_arn = module.sns.arn
# }

# module "flowlogs" {
#   source   = "./modules/security/flowlogs"
#   workload = local.workload
#   vpc_id   = module.vpc.vpc_id
# }



# module "security_group_inspection" {
#   source                   = "./modules/security/securitygroup/inspection"
#   workload                 = var.workload
#   vpc_id                   = module.vpc.vpc_id
#   secops_subnet_cidr_block = module.vpc.secops_subnet_cidr_block
# }
