resource "aws_security_group" "main" {
  name        = "isolated-security-group"
  description = "Isolated security group used to Quarantine EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.workload}-isolated-security-group"
  }
}
