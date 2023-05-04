provider "aws" {
  region = "ap-northeast-2"
}

module "webserver_cluster" {
  source                 = "../../../modules/services/webserver-cluster"
  cluster_name           = "webservers-stage"
  db_remote_state_bucket = var.db_remote_state_bucket
  db_remote_state_key    = var.db_remote_state_key
  instance_type          = var.instance_type
  min_size               = var.min_size
  max_size               = var.max_size
}
