output "kms_key" {
  value = aws_kms_key.sops_key.arn
}
