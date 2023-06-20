resource "aws_kms_key" "sops_key" {
  description             = "Key for sops"
  deletion_window_in_days = 7
}
