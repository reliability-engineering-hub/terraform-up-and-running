module "network" {
  source = "../../../../modules/vpc"

  region                    = "ap-northeast-2"
  vpc_name                  = "dev"
  vpc_cidr_block            = "10.101.0.0/16"
  public_subnet_cidr_block  = "10.101.1.0/24"
  private_subnet_cidr_block = "10.101.2.0/24"
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  vpc_id               = module.network.aws_vpc_id
  region               = "ap-northeast-2"
  server_port          = 8080
  cluster_name         = "webservers-dev"
  instance_type        = "t2.micro"
  min_size             = 1
  max_size             = 1
  enable_autoscaling   = false
  enable_new_user_data = true

  custom_tags = {
    Owner    = "cwlee"
    DeployBy = "terraform"
  }
}
