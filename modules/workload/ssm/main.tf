locals {
  config_file = file("${path.module}/config.json")
}

resource "aws_ssm_parameter" "cloudwath_config_file" {
  name  = "AmazonCloudWatch-linux-terraform"
  type  = "String"
  value = local.config_file
}

resource "aws_ssm_parameter" "private_key_openssh" {
  name  = "${var.workload}-private-key-openssh"
  type  = "SecureString"
  value = var.private_key_openssh
}
