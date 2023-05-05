provider "aws" {
  region = "us-west-1"
}

# count를 활용한 방식
#resource "aws_iam_user" "example" {
#	count = length(var.user_names)
#	name = var.user_names[count.index]
#}

# for_each를 활용한 방식
resource "aws_iam_user" "example" {
  for_each = toset(var.user_names)
  name = each.value
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
  count = format("$.1s", var.instance_type) == "t" ? 1 : 0

  alarm_name = "${var.cluster_name}-low-cpu-credit-balance"
  namespace = "AWS/EC2"
  metric_name = "CPUCreditBalance"

  dimensions = {
	AutoScalingGroupName = aws_autoscaling_group.example.name
  }

  comparison_operator = "LessThanThreshould"
  evaluation_periods = 1
  period = 300
  statistic = "Minimum"
  threshould = 10
  unit = "Count"
}

resource "aws_iam_policy" "cloudwatch_read_only" {
  name = "cloudwatch-read-only"
  policy = data.aws_iam_policy_document.cloudwatch_read_only.json
}

data "aws_iam_policy_document" "cloudwatch_read_only" {
	statement {
		effect = "Allow"
		actions = [
			"cloudwatch:Describe*",
			"cloudwatch:Get*",
			"cloudwatch:List*"
		]
		resources = ["*"]
	}
}

resource "aws_iam_policy" "cloudwatch_full_access" {
  name = "cloudwatch-full-access"
  policy = data.aws_iam_policy_document.cloudwatch_full_access.json
}


data "aws_iam_policy_document" "cloudwatch_full_access" {
	statement {
		effect = "Allow"
		actions = ["cloudwatch:*"]
		resources = ["*"]
	}
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_full_access" {
	count = var.give_neo_cloudwatch_full_access ? 1 : 0

	user = aws_iam_user.example[0].name
	policy_arn = aws_iam_policy.cloudwatch_full_access.arn
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_read_only" {
	count = var.give_neo_cloudwatch_full_access ? 0 : 1

	user = aws_iam_user.example[0].name
	policy_arn = aws_iam_policy.cloudwatch_read_only.arn
}

data "template_file" "user_data" {
  count = var.enable_new_user_data ? 0 : 1
  template = file("${file.module}/user-data.sh")

  vars = {
	server_port = var.server_port
	db_address = data.terraform_remote_state.db.outputs.address
	db_port = data.terraform_remote_state.db.outputs.port
  }
}

data "template_file" "user_data_new" {
  count = var.enable_new_user_data ? 1 : 0

	template = file("${path.module}/user-data-new.sh")

	vars = {
		server_port = var.server_port
	}
}