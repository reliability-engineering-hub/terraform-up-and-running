output "alb_dns_name" {
  value       = module.alb.aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = module.asg.aws_autoscaling_group.example.name
  description = "The name of the Auto Scaling Group"
}

output "instance_security_group_id" {
  value       = module.asg.instance_security_group_id
  description = "The ID of the EC2 Instance Security Group"
}
