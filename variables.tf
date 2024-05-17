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
variable "enable_ec2" {
  type = bool
}

variable "enable_fargate_service" {
  type = bool
}

variable "workload_type" {
  type        = string
  description = "Defines if the workload is created with an ASG or an instance"
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

### Fargate ###
variable "enable_fargate" {
  type = bool
}

variable "ecs_task_cpu" {
  type = number
}

variable "ecs_task_memory" {
  type = number
}

### SNS ###
variable "sns_email" {
  type = string
}

### Route 53 DNS Firewall ###
variable "route53_dns_firewall_blocked_domains" {
  type = list(string)
}
