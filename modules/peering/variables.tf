variable "security_requester_vpc_id" {
  type = string
}

variable "workload_accepter_vpc_id" {
  type = string
}

variable "security_requester_route_table_id" {
  type = string
}

variable "workload_accepter_route_table_id" {
  type = string
}

variable "security_requester_vpc_cidr_block" {
  type = string
}

variable "workload_accepter_vpc_cidr_block" {
  type = string
}
