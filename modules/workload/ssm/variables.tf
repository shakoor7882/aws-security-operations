variable "workload" {
  type = string
}

variable "private_key_openssh" {
  type      = string
  sensitive = true
}
