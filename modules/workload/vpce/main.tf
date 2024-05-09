### VPC Endpoints for Session Manager ###
# https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-create-vpc.html
# https://repost.aws/knowledge-center/ec2-systems-manager-vpc-endpoints

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  vpce_services = [
    "ssm",
    "ec2messages",
    "ec2",
    "ssmmessages",
    "logs",
    "ssm-incidents"
  ]
  subnet_ids         = [var.subnet_id]
  security_group_ids = [aws_security_group.session_manager.id]
}

resource "aws_vpc_endpoint" "session_manager" {
  for_each            = toset(local.vpce_services)
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  auto_accept         = true
  private_dns_enabled = true
  subnet_ids          = local.subnet_ids
  ip_address_type     = "ipv4"
  security_group_ids  = local.security_group_ids

  tags = {
    Name = "vpce-${var.workload}-${each.value}"
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "session_manager" {
  name   = "vpce-${var.workload}-sessionmanager"
  vpc_id = var.vpc_id

  tags = {
    Name = "sg-vpce-${var.workload}-sessionmanager"
  }
}

resource "aws_security_group_rule" "vpc_ingress_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.session_manager.id
}
