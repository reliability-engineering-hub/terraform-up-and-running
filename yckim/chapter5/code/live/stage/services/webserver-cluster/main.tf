provider "aws" {
  region = "us-west-1"
}

module "webserver_cluster" {
  source = "../../modules/service/webserver-cluster"

	ami = "ami-0c55b159cbfafe1f0"
	server_text = "New server text"
	
  cluster_name = "webservers-stage"
  db_remote_state_bucket = "terraform-up-and-learning-yckim"
  db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
  enable_autoscaling = false
}

resource "aws_launch_configuration" "example" {
	image_id = "ami-0c55b159cbfafe1f0"
	instance_type = var.instance_type
	security_groups = [aws_security_group.instance.id]

	user_data = (
		length(data.template_file.user_data[*]) > 0
		? data.template_file.user_data[0].rendered
		: data.template_file.user_data_new[0].rendered
	)
  
  lifecycle {
	create_before_destroy = true
  }
}