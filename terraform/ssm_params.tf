resource "aws_ssm_parameter" "ssm_param_gcp_service_account_credential_json" {
  name  = "/${local.service_id}/GCP_SERVICE_ACCOUNT_CREDENTIAL_JSON"
  type  = "SecureString"
  value = data.sops_file.secrets.data["service_credentials_json"]
}

resource "aws_ssm_parameter" "ssm_param_slack_api_token" {
  name  = "/${local.service_id}/SLACK_API_TOKEN"
  type  = "SecureString"
  value = data.sops_file.secrets.data["slack_api_token"]
}
