variable "aws_region" {
  type        = string
  description = "The region of aws"
}

variable "s3_bucket_name" {
  type        = string
  description = "The name of S3 bucket"
}

variable "dynamodb_table_name" {
  type        = string
  description = "The name of DynamoDB table"
}