data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_vpc_endpoint" "default" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type   = "Interface"
  auto_accept         = true
  private_dns_enabled = true

  dns_options {
    dns_record_ip_type = "ipv4"

    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint#private_dns_only_for_inbound_resolver_endpoint
    # Indicates whether to enable private DNS only for inbound endpoints.
    # This option is available only for services that support both gateway
    # and interface endpoints. It routes traffic that originates from the
    # VPC to the gateway endpoint and traffic that originates from on-premises
    # to the interface endpoint.
    private_dns_only_for_inbound_resolver_endpoint = true
  }

  subnet_ids         = [var.subnet_id]
  ip_address_type    = "ipv4"
  security_group_ids = [aws_security_group.default.id]

  tags = {
    Name = "vpce-${var.workload}-s3-interface"
  }
}

resource "aws_vpc_endpoint_policy" "default" {
  vpc_endpoint_id = aws_vpc_endpoint.default.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "Policy1415115909151",
    "Statement" : [
      { "Sid" : "Access-to-specific-bucket-only",
        "Principal" : "*",
        "Action" : [
          "s3:*",
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::${var.bucket}",
          "arn:aws:s3:::${var.bucket}/*"
        ]
      }
    ]
  })
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "default" {
  name   = "vpce-${var.workload}-vpce-s3-interface"
  vpc_id = var.vpc_id

  tags = {
    Name = "sg-vpce-${var.workload}"
  }
}

resource "aws_security_group_rule" "vpc_ingress_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.default.id
}
