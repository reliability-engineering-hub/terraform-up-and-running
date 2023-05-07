data "aws_vpc" "default" {
  id = var.vpc_id
}

# get all subnets from aws vpc
data "aws_subnet_ids" "default" {
  # set vpc_id from data (aws_vpc)
  vpc_id = data.aws_vpc.default.id
}

data "template_file" "user_data" {
  count    = var.enable_new_user_data ? 0 : 1
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
  }
}


data "template_file" "user_data_new" {
  count    = var.enable_new_user_data ? 1 : 0
  template = file("${path.module}/user-data-new.sh")

  vars = {
    server_port = var.server_port
  }
}
