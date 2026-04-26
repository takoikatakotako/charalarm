locals {
  service     = "charalarm"
  environment = "staging"
  prefix      = "${local.service}-${local.environment}"
}
