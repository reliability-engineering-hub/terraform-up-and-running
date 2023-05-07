provider "aws" {
  region = "ap-northeast-2"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  vpc_id                 = var.vpc_id
  region                 = "ap-northeast-2"
  ami                    = var.ami
  server_port            = 8080
  cluster_name           = "webservers-dev"
  db_remote_state_bucket = var.db_remote_state_bucket
  db_remote_state_key    = var.db_remote_state_key
  instance_type          = "t2.micro"
  min_size               = 1
  max_size               = 1
  enable_autoscaling     = false

  custom_tags = {
    Owner    = "cwlee"
    DeployBy = "terraform"
  }
}
