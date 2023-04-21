variable "region" {
  description = "The region of AWS"
  type        = string
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
}

variable "vpc_id" {
  description = "The id of default vpc"
  type        = string
}

variable "subnet_id" {
  description = "The id of default subnet"
  type        = string
}
