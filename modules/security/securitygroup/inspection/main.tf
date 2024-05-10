data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "inspection" {
  name        = "${var.workload}-secops-inspection"
  description = "Attach to an instance for inspection via SSH."
  vpc_id      = var.vpc_id

  tags = {
    Name = "sg-${var.workload}-secops-inspection"
  }
}

resource "aws_security_group_rule" "secops_subnet_ingress_ssh" {
  description       = "Allows SSH connections from the SecOps subnet."
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.secops_subnet_cidr_block]
  security_group_id = aws_security_group.inspection.id
}
