variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type = string
}

variable "db_remote_state_key" {
	description = "The path for the databases's remote state in S3"
	type = string
}

locals {
  	http_port = 80
	any_port = 0
	any_protocol = "-1"
	tcp_protocol = "tcp"
	all_ips = ["0.0.0.0/0"]	
}

variable "custom_tags" {
  description = "Custom tag in ASG"
	type = map(string)
	default = {}
}

variable "enable_autoscaling" {
  description = "If set to true, enable auto scaling"
  type = bool
}

variable "enable_new_user_data" {
  description = "If set to true, use the new User Data Script"
  type = bool
}

variable "ami" {
  description = "The AMI to run in the cluster"
  default = "ami-0c55b159cbfafe1f0"
  type = string
}

variable "server_text" {
  description = "The text the web server should return"
  default = "Hello, world"
  type = string
}