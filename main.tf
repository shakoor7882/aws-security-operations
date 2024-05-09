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

module "ssm" {
  source = "./modules/workload/ssm"
}

module "instance" {
  source        = "./modules/workload/ec2"
  vpc_id        = module.vpc.vpc_id
  subnet        = module.vpc.private_workload_subnet_id
  ami           = var.ami
  instance_type = var.instance_type
  user_data     = var.user_data

  depends_on = [module.ssm, module.vpce_workload]
}

module "vpce_workload" {
  source    = "./modules/workload/vpce"
  workload  = local.workload
  region    = var.aws_region
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.vpce_workload_subnet_id
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
