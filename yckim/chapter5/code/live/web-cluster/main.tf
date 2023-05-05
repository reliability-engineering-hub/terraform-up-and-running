resource "aws_autoscaling_group" "example" {
	launch_configuration = aws_launch_configuration.example.name
	vpc_zone_identifier = data.aws_subnet_ids.default.ids
	target_group_arns = [aws_lb_taget_group.asg.arn]
	health_check_type = "ELB"

	min_size = var.min_size
	max_size = var.max_size

	tag {
		key = "Name"
		value = var.cluster_name
		propagate_at_launch = true
	}

	dynamic "tag" {
	  for_each = var.custom_tags

	  content {
		key = tag.key
		value = tag.value
		propagate_at_launch = true
	  }
	}
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
	count = var.enable_autoscaling ? 1 : 0

	scheduled_action_name = "${var.cluster_name}-scale-out-during-business-hours"
	min_size = 2
	max_size = 10
	desired_capacity = 10
	recurrence = "0 9 * * *"

	autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
	count = var.enable_autoscaling ? 1 : 0

	scheduled_action_name = "${var.cluster_name}-scale_in_at_night"
	min_size = 2
	max_size = 10
	desired_capacity = 2
	recurrence = "0 17 * * *"

	autoscaling_group_name = module.webserver_cluster.asg_name
}

module "webserver_cluster" {
  source = "../../modules/service/webserver-cluster"

  cluster_name = "webservers-prod"
  db_remote_state_bucket = "terraform-up-and-learning-yckim"
  db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"

  instance_type = "m4.large"
  min_size = 2
  max_size = 10
  enable_autoscaling = true
  enable_new_user_data = true

  custom_tags = {
	Owner = "team-foo"
	DeployedBy = "terraform"
  }
}