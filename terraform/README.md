This terraform directory manages AWS resources needed to run Lambda (e.g. Lambda execution IAM roles, SSM Parameter Store, etc.)

## 🔨 Prerequisites
- [tflint](https://github.com/terraform-linters/tflint)
- [sops](https://github.com/mozilla/sops)

## 💨 Set up

Create KMS Key for sops

```
terraform init
terraform apply -auto-approve --target=module.kms
```

Configure SOPS_KMS_ARN value in `.envrc`

```
export SOPS_KMS_ARN='arn:aws:kms:<region>:account_id:key/xxx'
```

Configure your Lambda ARN in `.env`

```
cat << EOF > .env
TF_VAR_lambda_arn='arn:aws:lambda:<region>:<account_id>:function:xxx'
EOF
```

Then encrypt it with sops, and then write it to `.enc.env`

```
sops -e .env > .enc.env
```

Create `secrets.yml` which includes following secrets by using sops

```
sops secrets.yml
```

- `service_credentials_json`
    - Authentication key for Google service accounts
- `slack_api_token`
    - API token to notify the desired Slack channel

Looks like this

```yaml
service_credentials_json: ENC[AES256_GCM,data:sqhd,iv:kBRor1tBMHD1QuQxUN723bs1v5HQO33yHK2SpnqxoEA=,tag:dwCsLpOKoOSNByO6+NWziQ==,type:str]
slack_api_token: ENC[AES256_GCM,data:rQYc,iv:72cqjhUThUowSmmD+3f+OtWaw8l6oG4QS2sv6niFzhU=,tag:SEWyCL5IKwI16FH8kgcZLw==,type:str]
sops:
    kms:
        - arn: arn:aws:kms:<region>:<account_id>:key/xxx
          created_at: "2023-06-10T07:18:27Z"
          enc: xxx
          aws_profile: ""
    gcp_kms: []
    azure_kv: []
    hc_vault: []
    age: []
    lastmodified: "2023-06-20T01:37:37Z"
    mac: xxx
    pgp: []
    unencrypted_suffix: _unencrypted
    version: 3.7.3
```

## 🚀 Terraform Plan & Apply

```
make plan
```

```
make apply
```

---

## 🪣  tfstate management
- tfstate is managed on s3 backend by using [terraform-aws-tfstate-backend](https://github.com/cloudposse/terraform-aws-tfstate-backend)

## 🔐 Secrets
- Secrets is saved on secrets.yml and it's managed by [sops](https://github.com/mozilla/sops)
- Secrets is referred from terraform provider of [terraform-provider-sops](https://github.com/carlpett/terraform-provider-sops)

