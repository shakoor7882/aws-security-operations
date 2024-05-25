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

variable "enable_waf" {
  type = bool
}

variable "waf_allowed_country_codes" {
  type = list(string)
}

variable "waf_rate_limit" {
  type = number
}

variable "waf_rate_evaluation_window_sec" {
  type = number
}
