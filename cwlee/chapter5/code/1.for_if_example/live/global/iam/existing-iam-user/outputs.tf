
## count문 예제

/*
output "neo_arn" {
  value       = aws_iam_user.example[0].arn
  description = "The ARN for user Neo"
}

output "all_arns" {
  value       = aws_iam_user.example[*].arn
  description = "The ARNs for all users"
}
*/

# output "all_users" {
#   value = aws_iam_user.example
# }

# output "all_arns" {
#   value = values(aws_iam_user.example)[*].arn
# }

# output "upper_names" {
#   value = [for name in var.user_names : upper(name) if length(name) < 5]
# }

# output "for_directive" {
#   value = <<EOF
# %{~for name in var.user_names}
#   ${name}
# %{~endfor}
# EOF
# }

# output "bios" {
#   value = [for name, role in var.hero_thousand_faces : "${name} is the ${role}"]
# }

output "upper_roles" {
  value = { for name, role in var.hero_thousand_faces : upper(name) => upper(role) }
}

output "if_else_directive" {
  value = "Hello, %{ if var.name != "" }${var.name}%{ else }{unnamed}%{ endif }"
}