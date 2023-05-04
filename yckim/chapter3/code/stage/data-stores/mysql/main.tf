provider "aws" {
  region = "us-west-1"
}

resource "aws_db_instance" "example" {
	identifier_prefix = "terraform-up-and-running"
	engine = "mysql"
	allocated_storage = 10
	instance_class = "db.t2.micro"
	name = "example_database"
	username = "admin"
	password = data.aws_secretmanager_secret_version.db_password.secret_string
}

data "aws_secretmanager_secret_version" "db_password" {
	secret_id = "mysql-master-password-stage"
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
	bucket = "terraform-up-and-running-state-yckim"
	key = "stage/data-stores/mysql/terraform.tfstate"
	region = "us-west-1"
   }
}