output "ctl_api_config" {
  description = "The three ctl-api config values this module produces, keyed by config name."
  value = {
    AWS_PHONE_HOME_CMK_ARN          = aws_kms_key.phone_home.arn
    AWS_PHONE_HOME_SECRETS_ROLE_ARN = aws_iam_role.phone_home_secrets.arn
    MANAGEMENT_REGION               = data.aws_region.current.region
  }
}

output "phone_home_cmk_arn" {
  description = "ARN of the CMK encrypting phone-home secrets. ctl-api AWS_PHONE_HOME_CMK_ARN."
  value       = aws_kms_key.phone_home.arn
}

output "phone_home_cmk_alias" {
  description = "Alias of the phone-home CMK."
  value       = aws_kms_alias.phone_home.name
}

output "phone_home_secrets_role_arn" {
  description = "ARN of the role ctl-api assumes. ctl-api AWS_PHONE_HOME_SECRETS_ROLE_ARN."
  value       = aws_iam_role.phone_home_secrets.arn
}

output "phone_home_secrets_role_name" {
  description = "Name of the role ctl-api assumes."
  value       = aws_iam_role.phone_home_secrets.name
}

output "management_region" {
  description = <<-EOT
    Region the CMK and secrets live in. ctl-api MANAGEMENT_REGION, and the value baked
    into each customer Lambda as NUON_PHONE_HOME_SECRET_REGION.
  EOT
  value       = data.aws_region.current.region
}

output "secret_arn_pattern" {
  description = "ARN pattern the secrets role is scoped to, for debugging AccessDenied on provision."
  value       = local.secret_arn_pattern
}
