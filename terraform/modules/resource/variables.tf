variable "bucket_name" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "domain" {
  type = string
}

# ブラウザから署名付き URL で PUT してよいオリジン (管理画面)。空なら CORS を付けない
variable "cors_allowed_origins" {
  type    = list(string)
  default = []
}
