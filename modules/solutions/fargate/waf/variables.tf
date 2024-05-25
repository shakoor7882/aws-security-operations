variable "resource_arn" {
  type = string
}

variable "workload" {
  type = string
}

variable "allowed_country_codes" {
  type = list(string)
}

variable "rate_limit" {
  type = number
}

variable "rate_evaluation_window_sec" {
  type = number
}
