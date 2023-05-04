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