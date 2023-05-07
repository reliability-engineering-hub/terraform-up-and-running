provider "aws" {
  region = var.region
}

resource "aws_vpc" "dev" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = var.public_subnet_cidr_block
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "${var.vpc_name}-public-subent"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = var.private_subnet_cidr_block
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "${var.vpc_name}-private-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}
