resource "aws_scheduler_schedule_group" "lambda_eventbridge_scheduler_group" {
  name = "${local.service_id}-scheduler-group"
}

resource "aws_scheduler_schedule" "lambda_eventbridge_scheduler_schedule" {
  name                         = "${local.service_id}-lambda-scheduler-schedule"
  group_name                   = aws_scheduler_schedule_group.lambda_eventbridge_scheduler_group.name
  schedule_expression          = "cron(0 9 * * ? *)"
  schedule_expression_timezone = "UTC"
  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = var.lambda_arn
    role_arn = aws_iam_role.lambda_eventbridge_scheduler_iam_role.arn
  }
}

resource "aws_iam_role" "lambda_eventbridge_scheduler_iam_role" {
  name               = "${local.service_id}-lambda-scheduler-role"
  assume_role_policy = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "scheduler.amazonaws.com"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY

  managed_policy_arns  = [aws_iam_policy.lambda_eventbridge_scheduler_iam_policy.arn]
  max_session_duration = "3600"
  path                 = "/service-role/"
}

resource "aws_iam_policy" "lambda_eventbridge_scheduler_iam_policy" {
  name = "${local.service_id}-lambda-scheduler-policy"
  path = "/service-role/"

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${var.lambda_arn}"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}
