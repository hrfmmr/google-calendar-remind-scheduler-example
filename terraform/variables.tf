data "aws_caller_identity" "current" {}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "lambda_arn" {
  type = string
}
