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
  workload          = local.solution_workload
  availability_zone = local.availability_zone
}

# module "vpc_peering" {
#   source                       = "./modules/vpc/peering"
#   bastion_requester_vpc_id     = module.vpc_bastion.vpc_id
#   solution_accepter_vpc_id     = module.vpc_solution.vpc_id
#   solution_accepter_vpc_region = var.solution_region

#   bastion_requester_route_table_id = module.vpc_bastion.route_table_id
#   bastion_requester_vpc_cidr_block = module.vpc_bastion.cidr_block

#   solution_accepter_route_table_id = module.vpc_solution.route_table_id
#   solution_accepter_vpc_cidr_block = module.vpc_solution.cidr_block
# }



# module "vpce_solution" {
#   source    = "./common/vpce"
#   workload  = local.solution_workload
#   region    = var.aws_region
#   vpc_id    = module.vpc_solution.vpc_id
#   subnet_id = module.vpc_solution.vpce_solution_subnet_id
# }

# module "ssm" {
#   source              = "./modules/workload/ssm"
#   workload            = var.workload
#   private_key_openssh = tls_private_key.generated_key.private_key_openssh
# }

# module "instance" {
#   source             = "./modules/workload/ec2"
#   vpc_id             = module.vpc.vpc_id
#   subnet             = module.vpc.private_workload_subnet_id
#   ami                = var.ami
#   instance_type      = var.instance_type
#   user_data          = var.user_data
#   public_key_openssh = tls_private_key.generated_key.public_key_openssh

#   depends_on = [module.ssm, module.vpce_workload]
# }



# module "route53" {
#   source                    = "./modules/workload/route53"
#   vpc_id                    = module.vpc.vpc_id
#   instance_private_dns      = module.instance.private_dns
#   security_jump_private_dns = module.security_jumpserver.private_dns
# }

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

# module "security_jumpserver" {
#   source        = "./modules/security/jumpserver"
#   vpc_id        = module.vpc.vpc_id
#   subnet        = module.vpc.secops_subnet_id
#   ami           = var.ami
#   instance_type = var.instance_type
#   user_data     = var.user_data
# }

# module "security_group_inspection" {
#   source                   = "./modules/security/securitygroup/inspection"
#   workload                 = var.workload
#   vpc_id                   = module.vpc.vpc_id
#   secops_subnet_cidr_block = module.vpc.secops_subnet_cidr_block
# }
