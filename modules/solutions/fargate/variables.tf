variable "workload" {
  type = string
}

variable "region" {
  type = string
}

variable "ecs_task_cpu" {
  type = number
}

variable "ecs_task_memory" {
  type = number
}

variable "vpc_id" {
  type = string
}

variable "elb_subnet_ids" {
  type = list(string)
}

variable "ecs_subnet_ids" {
  type = list(string)
}

variable "enable_fargate_service" {
  type = bool
}

variable "vpce_subnet_id" {
  type = string
}
