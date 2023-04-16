variable "map_example" {
	description = "An example of a map in Terraform"
  	type = map(string)
  	default = {
		key1 = "value1"
		key2 = "value2"
		key3 = "value3"
	}
}