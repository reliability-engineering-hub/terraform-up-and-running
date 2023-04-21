variable "list_numeric_example" {
	description = "An example of a numeric list in Terraform"
  	type = list(number)
  	default = [1, 2, 3]
}