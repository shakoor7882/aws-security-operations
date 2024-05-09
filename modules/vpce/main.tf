### GuardDuty Runtime Monitoring ###

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_vpc_endpoint" "guardduty" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.guardduty-data"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.guardduty.id]

  tags = {
    Name = "guardduty-vpce"
  }
}

resource "aws_vpc_endpoint_subnet_association" "instance" {
  vpc_endpoint_id = aws_vpc_endpoint.guardduty.id
  subnet_id       = var.subnet_id
}

resource "aws_vpc_endpoint_policy" "main" {
  vpc_endpoint_id = aws_vpc_endpoint.guardduty.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "*",
        "Resource" : "*",
        "Effect" : "Allow",
        "Principal" : "*"
      },
      {
        "Condition" : {
          "StringNotEquals" : {
            "aws:PrincipalAccount" : "${local.account_id}"
          }
        },
        "Action" : "*",
        "Resource" : "*",
        "Effect" : "Deny",
        "Principal" : "*"
      }
    ]
  })
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "guardduty" {
  name   = "vpce-guardduty-sg"
  vpc_id = var.vpc_id

  tags = {
    Name = "sg-vpce-guardduty"
  }
}

resource "aws_security_group_rule" "vpce_ingress_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.guardduty.id
}
