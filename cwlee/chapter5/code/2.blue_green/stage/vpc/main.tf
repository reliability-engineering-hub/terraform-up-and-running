provider "aws" {
  region = "ap-northeast-2"
}

module "network" {
  source = "../../modules/vpc"

  region                    = "ap-northeast-2"
  vpc_name                  = "dev"
  vpc_cidr_block            = "10.101.0.0/16"
  public_subnet_cidr_block  = "10.101.1.0/24"
  private_subnet_cidr_block = "10.101.2.0/24"
}
