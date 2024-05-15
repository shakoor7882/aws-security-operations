locals {
  name = "asg-infected-instance"
}

resource "aws_autoscaling_group" "default" {
  name                = "${local.name}-${var.workload}"
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [var.subnet]

  health_check_type         = "EC2"
  health_check_grace_period = 60
  force_delete              = true

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "default" {
  name = local.name
  role = aws_iam_role.main.id
}

resource "aws_key_pair" "deployer" {
  key_name   = "asg-${local.name}-${var.workload}-deployer-key"
  public_key = var.public_key_openssh
}

resource "aws_launch_template" "main" {
  name = "launchtemplate-${local.name}-${var.workload}"

  image_id      = var.ami
  instance_type = var.instance_type

  user_data = filebase64("${path.module}/userdata/al2023.sh")
  key_name  = aws_key_pair.deployer.key_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.default.arn
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  ebs_optimized = true

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.main.id]
    delete_on_termination       = true
    subnet_id                   = var.subnet
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = local.name
    }
  }
}

### IAM Role ###
resource "aws_iam_role" "main" {
  name = "${local.name}-role"

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

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "main" {
  name        = "ec2-ssm-${local.name}"
  description = "Controls access for EC2 via Session Manager"
  vpc_id      = var.vpc_id

  tags = {
    Name = "sg-ssm-${local.name}"
  }
}

resource "aws_security_group_rule" "icmp_egress" {
  type              = "egress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block, var.security_vpc_cidr_block]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "icmp_ingress" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block, var.security_vpc_cidr_block]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.security_vpc_cidr_block]
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
