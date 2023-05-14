provider "aws" {
  region  = "ap-northeast-2"
  version = "~> 2.0"
}

module "alb" {
  source     = "../../modules/networking/alb"
  alb_name   = var.alb_name
  vpc_id     = data.aws_vpc.dev.id
  subnet_ids = data.aws_subnet_ids.default.ids
}
