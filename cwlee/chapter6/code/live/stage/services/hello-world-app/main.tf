provider "aws" {
  region  = "ap-northeast-2"
  version = "~> 2.0"
}

module "hello_world_app" {
  # TODO : 사용자의 모듈 URL과 버전으로 변경 !!
  source = "git@github.com:foo/modules.git//services/hello-world-app?ref=v0.0.5"

  server_text            = "New server text"
  environment            = "stage"
  db_remote_state_bucket = "{YOUR_BUCKET_NAME}"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"

  instance_type      = "t2.micro"
  min_size           = 2
  max_size           = 2
  enable_autoscaling = false
}

