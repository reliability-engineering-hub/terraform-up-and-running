provider "aws" {
  region = "us-west-1"
}


resource "aws_instance" "example" {
	ami = "ami-014d05e6b24240371"
	instance_type = "t2.micro"
}

data "template_file" "user-data" {
  template = file("user-data.sh")

  vars = {
	"db_address" = data.terraform_remote_state.db.outputs.address
  }
}