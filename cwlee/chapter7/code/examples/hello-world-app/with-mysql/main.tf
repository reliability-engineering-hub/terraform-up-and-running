provider "aws" {
  region  = "ap-northeast-2"
  version = "~> 2.0"
}

module "hello_world_app" {
  source = "../../modules/services/hello-world-app"

  server_text = "Hello, World"
  environment = "example"

  mysql_config = module.mysql

  instance_type      = "t2.micro"
  min_size           = 2
  max_size           = 2
  enable_autoscaling = false
}

module "mysql" {
  source = "../../../modules/data-stores/mysql"

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}
