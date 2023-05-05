output "asg_name" {
	value = aws_autoscaling_group.example.name
	description = "The name of the Auto Scaling Group"
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
  description = "The Id of the Security Group attached to the load balancer"
}