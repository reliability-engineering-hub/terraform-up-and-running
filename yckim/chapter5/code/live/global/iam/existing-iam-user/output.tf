# count
#
#output "neo_arns" {
#  value = aws_iam_user.example[0].arn
#  description = "The ARN for user Neo"
#}

#output "all_arns" {
#  value = aws_iam_user.example[*].arn
#  description = "The ARN for all users"
#}

# for_each
#
output "all_users" {
value = aws_iam_user.example
}

output "all_arns" {
	value = values(aws_iam_user.example)[*].arn
}

# for
#
output "upper_names" {
	value = [for name in var.names : upper(name)]
}

output "short_upper_names" {
	value = [for name in var.names : upper(name) if length(name) < 5]
}

output "bios" {
	value = [for name, role in var.var.hero_thousand_faces : "${name} is the ${role}"]
}

output "upper_roles" {
	value = {for name, role in var.var.hero_thousand_faces : upper(name) => upper(role)}
}

output "for_directive" {
  value = <<EOF
  %{~ for name in var.names }
	${name}
  %{~ endfor }
  EOF
}