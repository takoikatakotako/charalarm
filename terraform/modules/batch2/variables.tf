# variable "resource_domain" {
#   type = string
# }


variable "batch_function_image_uri" {
  type = string
}

variable "batch_function_image_tag" {
  type = string
}

locals {
  environment_variables = {
    # "RESOURCE_BASE_URL" = "https://${var.resource_domain}"
  }
}