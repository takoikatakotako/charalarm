provider "aws" {
  profile = "charalarm-staging-sso"
  region  = "ap-northeast-1"
}

provider "aws" {
  alias   = "virginia"
  profile = "charalarm-staging-sso"
  region  = "us-east-1"
}
