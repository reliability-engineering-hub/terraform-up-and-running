variable "aws_region" {
  type        = string
  description = "The region of aws"
}

variable "vpc_id" {
  type        = string
  description = "The id of default VPC"
}

variable "db_password" {
  description = "The password for the database"
  type        = string
}
