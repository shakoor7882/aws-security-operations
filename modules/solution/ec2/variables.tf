variable "vpc_id" {
  type = string
}

variable "subnet" {
  type = string
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "user_data" {
  type = string
}

variable "public_key_openssh" {
  type      = string
  sensitive = true
}

variable "route53_zone_id" {
  type = string
}
