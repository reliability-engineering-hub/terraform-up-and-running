data "aws_vpc" "default" {
  id = var.vpc_id
}

# get all subnets from aws vpc
data "aws_subnet_ids" "default" {
  # set vpc_id from data (aws_vpc)
  vpc_id = data.aws_vpc.default.id
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    region = "ap-northeast-2"
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
    server_text = var.server_text
  }
}
