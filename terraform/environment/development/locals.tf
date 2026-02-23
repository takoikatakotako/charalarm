locals {
  service     = "charalarm"
  environment = "dev"
  prefix      = "${local.service}-${local.environment}"
}
