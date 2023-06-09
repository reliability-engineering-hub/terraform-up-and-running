provider "aws" {
  region = "ap-northeast-2"
}

terraform {
    backend "s3" {

    }
}


module "mysql" {
  source = "../../../../modules/data-stores/mysql"

  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}