provider "aws" {
  profile = "charalarm-production-sso"
  region  = "ap-northeast-1"
}

provider "aws" {
  alias   = "virginia"
  profile = "charalarm-production-sso"
  region  = "us-east-1"
}
