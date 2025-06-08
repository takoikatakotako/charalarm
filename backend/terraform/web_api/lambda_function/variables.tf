variable "function_name" {
  type = string
}

variable "role" {
  type = string
}

variable "s3_bucket" {
  type = string
}

variable "s3_key" {
  type = string
}

variable "execution_arn" {
  type = string
}

variable "method" {
  type = string
}

variable "path" {
  type = string
}

variable "environment_variables" {
  type = map(string)
}

variable "datadog_log_forwarder_arn" {
  type = string
}

