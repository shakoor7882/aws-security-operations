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
  workload = "bigbank"
}

### Workload ###
module "vpc" {
  source   = "./modules/workload/vpc"
  region   = var.aws_region
  workload = local.workload
}

resource "tls_private_key" "generated_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "ssm" {
  source              = "./modules/workload/ssm"
  workload            = local.workload
  private_key_openssh = tls_private_key.generated_key.private_key_openssh
}

module "instance" {
  source             = "./modules/workload/ec2"
  vpc_id             = module.vpc.vpc_id
  subnet             = module.vpc.private_workload_subnet_id
  ami                = var.ami
  instance_type      = var.instance_type
  user_data          = var.user_data
  public_key_openssh = tls_private_key.generated_key.public_key_openssh

  depends_on = [module.ssm, module.vpce_workload]
}

module "vpce_workload" {
  source    = "./modules/workload/vpce"
  workload  = local.workload
  region    = var.aws_region
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.vpce_workload_subnet_id
}

module "route53" {
  source                    = "./modules/workload/route53"
  vpc_id                    = module.vpc.vpc_id
  instance_private_dns      = module.instance.private_dns
  security_jump_private_dns = module.security_jumpserver.private_dns
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

module "security_jumpserver" {
  source        = "./modules/security/jumpserver"
  vpc_id        = module.vpc.vpc_id
  subnet        = module.vpc.secops_subnet_id
  ami           = var.ami
  instance_type = var.instance_type
  user_data     = var.user_data
}

module "security_group_inspection" {
  source                   = "./modules/security/securitygroup/inspection"
  workload                 = local.workload
  vpc_id                   = module.vpc.vpc_id
  secops_subnet_cidr_block = module.vpc.secops_subnet_cidr_block
}
