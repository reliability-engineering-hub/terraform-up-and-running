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
