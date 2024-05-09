### AWS ###
variable "aws_region" {
  type    = string
  default = "us-east-2"
}

### GuardDuty ###
variable "enable_guardduty" {
  type = bool
}

variable "enable_guardduty_runtime_monitoring" {
  type = bool
}

### EC2 ###
variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "user_data" {
  type = string
}

### SNS ###
variable "sns_email" {
  type = string
}
