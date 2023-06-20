resource "aws_iam_role" "lambda_exec_iam_role" {
  assume_role_policy = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY

  managed_policy_arns  = [aws_iam_policy.lambda_exec_iam_policy.arn]
  max_session_duration = "3600"
  name                 = "${local.service_id}-lambda-exec-role"
  path                 = "/service-role/"
}

resource "aws_iam_policy" "lambda_exec_iam_policy" {
  name = "${local.service_id}-lambda-exec-policy"
  path = "/service-role/"

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": "logs:CreateLogGroup",
      "Effect": "Allow",
      "Resource": "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
    },
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.service_id}:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters"
      ],
      "Resource": "arn:aws:ssm:*:*:parameter/${local.service_id}/*"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}
