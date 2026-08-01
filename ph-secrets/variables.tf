locals {
  # Both of these are hardcoded on the ctl-api side with no config field, so neither is
  # a module variable: the only reachable effect of changing one here would be to make
  # the IAM grant stop matching what ctl-api actually does.
  #
  # The secret path ctl-api writes to, from secretsmanager.PhoneHomeSecretName —
  # nuon/phone-home/<install_id>. EnsureSecret passes that name to DescribeSecret and
  # CreateSecret, so a mismatch here fails every provision with AccessDenied.
  secret_name_prefix = "nuon/phone-home"

  # The customer-side Lambda role name, from stacks.PhoneHomeRoleName —
  # <install_id>-phone-home. This feeds both sides of the grant: the aws:PrincipalArn
  # condition on each secret's resource policy, and the RoleName CloudFormation gives
  # the Lambda's role. The key policy below has to match it.
  phone_home_role_name_pattern = "*-phone-home"

  secret_arn_pattern = format(
    "arn:aws:secretsmanager:%s:%s:secret:%s/*",
    data.aws_region.current.region,
    data.aws_caller_identity.current.account_id,
    local.secret_name_prefix,
  )
}

variable "ctl_api_sa_unique_id" {
  type        = string
  description = <<-EOT
    Numeric unique_id of the GCP service account ctl-api runs as (NOT its email). Used
    as the `sub` claim in the web-identity trust policy, so only that service account
    can assume the role.

      gcloud iam service-accounts describe <sa-email> --format='value(uniqueId)'
  EOT

  validation {
    # The email is the easy mistake, and it fails as an opaque AccessDenied at phone-home
    # time rather than at apply. Catch it here instead.
    condition     = can(regex("^[0-9]+$", var.ctl_api_sa_unique_id))
    error_message = "ctl_api_sa_unique_id must be the service account's numeric unique_id, not its email address."
  }
}

variable "name_prefix" {
  type        = string
  description = <<-EOT
    Prefix for the IAM role, IAM policy and KMS alias this module creates. Free to
    change: these are consumed as ARNs you copy into ctl-api's config, and nothing in
    ctl-api reconstructs them by name.
  EOT
  default     = "nuon"
}

variable "additional_trusted_role_arns" {
  type        = list(string)
  description = <<-EOT
    Extra IAM role ARNs allowed to assume the secrets role with plain sts:AssumeRole,
    for break-glass or debugging. ctl-api itself does not need this — it federates in
    via the GCP service account above.
  EOT
  default     = []
}

variable "kms_deletion_window_in_days" {
  type        = number
  description = "Waiting period before the CMK is destroyed after a delete is scheduled."
  default     = 7
}

variable "enable_key_rotation" {
  type        = bool
  description = "Enable annual automatic rotation of the CMK."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the resources this module creates."
  default     = {}
}
