variable "object_example" {
	description = "An example of a structural type in Terraform"
  	type = obejct({
		name = string
		age = number
		tags = list(string)
		enable = bool
	})
	default = {
		name = "value1"
		age = 42
		tags = ["a", "b", "c"]
		enabled = true
	}
}