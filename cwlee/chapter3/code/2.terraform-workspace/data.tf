data "aws_vpc" "default" {
  id = var.vpc_id
}

data "aws_subnet" "public_subnet" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "tag:Name"
    values = ["${var.subnet_name}"]
  }
}
