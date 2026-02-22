provider "aws" {
  profile = "charalarm-development-sso"
  region  = "ap-northeast-1"
}

provider "aws" {
  alias   = "virginia"
  profile = "charalarm-development-sso"
  region  = "us-east-1"
}
