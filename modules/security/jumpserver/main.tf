locals {
  # FIXME: typo
  name = "secops-jumpserver"
}

resource "aws_iam_instance_profile" "main" {
  name = local.name
  role = aws_iam_role.main.id
}

resource "aws_instance" "main" {
  ami           = var.ami
  instance_type = var.instance_type

  associate_public_ip_address = false
  subnet_id                   = var.subnet
  vpc_security_group_ids      = [aws_security_group.main.id]

  iam_instance_profile = aws_iam_instance_profile.main.id
  user_data            = file("${path.module}/userdata/${var.user_data}")

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring    = true
  ebs_optimized = true

  root_block_device {
    encrypted = true
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }

  tags = {
    Name = local.name
  }
}

### IAM Role ###

resource "aws_iam_role" "main" {
  name = "jumpserversecops"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMReadOnlyAccess" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_security_group" "main" {
  name        = "ec2-ssm-${local.name}"
  description = "Controls access for EC2 via Session Manager"
  vpc_id      = var.vpc_id

  tags = {
    Name = "sg-ssm-${local.name}"
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group_rule" "egress_ssh" {
  type              = "egress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_route53_record" "a" {
  zone_id = var.route53_zone_id
  name    = "secops-jumpserver"
  type    = "A"
  ttl     = 300
  records = [aws_instance.main.private_ip]
}
