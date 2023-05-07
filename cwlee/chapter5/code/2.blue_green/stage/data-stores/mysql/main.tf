provider "aws" {
  region = "ap-northeast-2"
}

module "data_stores" {
  source      = "../../../modules/data-stores/mysql"
  vpc_id      = var.vpc_id
  db_password = var.db_password
}

