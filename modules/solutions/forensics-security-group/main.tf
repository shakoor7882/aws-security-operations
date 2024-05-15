resource "aws_security_group" "main" {
  name        = "${var.workload}-forensics-security-group"
  description = "Use this security group to control access to the infected instances, from the forensics environment."
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.workload}-forensics-security-group"
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group_rule" "icmp_ingress" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = [var.security_vpc_cidr_block]
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
