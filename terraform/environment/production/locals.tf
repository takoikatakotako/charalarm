locals {
  service     = "charalarm"
  environment = "production"
  prefix      = "${local.service}-${local.environment}"
}
