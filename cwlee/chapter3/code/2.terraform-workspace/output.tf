output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "subnet_id" {
  value = data.aws_subnet.public_subnet.id
}

output "security_group_id" {
  value = aws_security_group.example.arn
}
