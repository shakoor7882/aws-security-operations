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

resource "aws_guardduty_detector" "main" {
  enable = true
}

resource "aws_guardduty_detector_feature" "runtime_monitoring" {
  detector_id = aws_guardduty_detector.main.id
  name        = "RUNTIME_MONITORING"
  status      = "ENABLED"

  additional_configuration {
    name   = "EKS_ADDON_MANAGEMENT"
    status = "DISABLED"
  }

  additional_configuration {
    name   = "ECS_FARGATE_AGENT_MANAGEMENT"
    status = "DISABLED"
  }

  additional_configuration {
    name   = "EC2_AGENT_MANAGEMENT"
    status = "ENABLED"
  }
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
