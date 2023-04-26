data "aws_vpc" "default" {
  id = var.vpc_id
}

# get all subnets from aws vpc
data "aws_subnet_ids" "default" {
  # set vpc_id from data (aws_vpc)
  vpc_id = data.aws_vpc.default.id
}

data "aws_security_group" "instance" {
  id = var.security_group_id
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    region = "ap-northeast-2"
    bucket = "terraform-up-and-running-state-lcw"
    key    = "stage/data-stores/mysql/terraform.tfstate"
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}
