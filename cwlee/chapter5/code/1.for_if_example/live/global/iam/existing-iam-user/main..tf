provider "aws" {
  region = "ap-northeast-2"
}

/*
## count문 예제

resource "aws_iam_user" "example" {
  count = length(var.user_names)
  name  = var.user_names[count.index]
}
*/

# resource "aws_iam_user" "example" {
#   for_each = toset(var.user_names)
#   name     = each.value
# }
