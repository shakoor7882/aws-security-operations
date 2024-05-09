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

module "guardduty" {
  source                    = "./modules/guardduty"
  enable_guardduty          = var.enable_guardduty
  enable_runtime_monitoring = var.enable_guardduty_runtime_monitoring
}

module "sns" {
  source = "./modules/sns"
  email  = var.sns_email
}

module "eventbridge" {
  source        = "./modules/eventbridge"
  sns_topic_arn = module.sns.arn
}

module "vpc" {
  source = "./modules/vpc"
  region = var.aws_region
}

module "flowlogs" {
  source   = "./modules/flowlogs"
  workload = local.workload
  vpc_id   = module.vpc.vpc_id
}

module "instance" {
  source        = "./modules/ec2"
  vpc_id        = module.vpc.vpc_id
  subnet        = module.vpc.subnets[0]
  ami           = var.ami
  instance_type = var.instance_type
  user_data     = var.user_data

  depends_on = [module.vpce]
}

module "vpce" {
  source    = "./modules/vpce"
  region    = var.aws_region
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.subnets[0]
}
