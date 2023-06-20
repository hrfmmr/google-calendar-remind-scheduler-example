module "terraform_state_backend" {
  source     = "cloudposse/tfstate-backend/aws"
  version    = "1.1.1"
  namespace  = "${local.service_id}.${local.s3_domain}"
  stage      = "prod"
  name       = "terraform"
  attributes = ["state"]

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
}

module "kms" {
  source = "./modules/kms"
}
