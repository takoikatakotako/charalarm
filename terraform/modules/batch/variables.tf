variable "resource_domain" {
  type = string
}


locals {
  environment_variables = {
    "RESOURCE_BASE_URL" = "https://${var.resource_domain}"
  }
}