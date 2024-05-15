locals {
  vpce_services = [
    "ecr.dkr",
    "ecr.api"
  ]
}

resource "aws_vpc_endpoint" "default" {
  for_each            = toset(local.vpce_services)
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  auto_accept         = true
  private_dns_enabled = true
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.default.id]

  tags = {
    Name = "vpce-${each.value}"
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "default" {
  name   = "vpce-ecr-sg"
  vpc_id = var.vpc_id

  tags = {
    Name = "sg-vpce-ecr"
  }
}

resource "aws_security_group_rule" "vpce_ingress_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.default.id
}
