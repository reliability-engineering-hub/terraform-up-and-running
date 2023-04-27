provider "aws" {
  region = "us-west-1"
}

module "webserver_cluster" {
  source = "github.com/foo/modules//webserver-cluster?ref=v0.0.1"
}