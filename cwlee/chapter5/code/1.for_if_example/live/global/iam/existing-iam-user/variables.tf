variable "user_names" {
  description = "Create IAM users with these names"
  type        = list(string)
  default     = ["neo", "morpheus"]
}


variable "hero_thousand_faces" {
  description = "map"
  type        = map(string)
  default = {
    neo      = "hero"
    trinity  = "love interest"
    morpheus = "mentor"
  }
}

variable "name" {
  description = "A name to render"
  type = string
}