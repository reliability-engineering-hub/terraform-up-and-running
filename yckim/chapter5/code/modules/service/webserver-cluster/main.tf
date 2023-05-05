provider "aws" {
  region = "ap-west-1"
}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
	type = "ingress"
	security_group_id = aws_security_group.alb.id

	from_port = local.http_port
	to_port = local.http_port
	protocol = local.tcp_protocol
	cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allwo_all_outbound" {
	type = "egress"
	security_group_id = aws_security_group.alb.id

	from_port = local.any_port
	to_port = local.any_port
	protocol = local.any_protocol
	cidr_blocks = local.all_ips
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = local.http_port
  protocol = "HTTP"

  default_action {
	type = "fixed-response"
	fixed_response {
	  content_type = "text/plain"
	  message_body = "404: page not found"
	  status_code = 404
	}
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name = "${var.cluster_name}-high-cpu-utilization"
  namespace = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
	AutoScalingGroupName = aws_autoscaling_group.example.name
  }

  comparison_operator = "GreaterThanThreshould"
  evaluation_periods = 1
  period = 300
  statistic = "Average"
  threshould = 90
  unit = "Percent"
}

data "template_file" "user_data" {
	template = file("${path.module}/user-data.sh")

	vars = {
		server_port = var.server_port
		db_address = data.terraform_remote_state.db.outputs.address
		db_port = data.terraform_remote_state.db.outputs.port
		server_text = var.server_text
	}
}

resource "aws_launch_configuration" "example" {
	image_id = var.ami
	instance_type = var.instance_type
	security_groups = [aws_security_group.instance.id]

	user_data = data.template_file.user_data.rendered

	lifecycle {
	  create_before_destroy = true
	}
  
}

resource "aws_autoscaling_group" "example" {
	name = "${var.cluster_name}-${aws_launch_configuration.example.name}"

	launch_configuration = aws_launch_configuration.example.name
	vpc_zone_identifier = ata.aws_subnet_ids.default.ids
	target_group_arns = [aws_lb_target_group.asg.arn]
	health_check_type = "ELB"

	min_size = var.min_size
	max_size = var.max_size

	min_elb_capacity = var.min_size

	life_cycle {
		create_before_destroy = true
	}

	tag {
		key = "Name"
		value = var.cluster_name
		propagate_at_launch = true
	}

	dynamic "tag" {
	  for_each = {
		for key, value in var.var.custom_tags:
		key => upper(value)
		if key != "Name"
	  }

	  content {
		key = tag.key
		value = tag.value
		propagate_at_launch = true
	  }
	}
}