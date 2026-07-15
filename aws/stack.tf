##
## Nuon control-plane configuration.
##
## Config (runner details, IAM permissions, roles, install inputs and secrets)
## is read from the Nuon API via the stack_config data source. For backward
## compatibility, any legacy variable that is set takes precedence over the
## data source (see legacy.tf); when phone_home_id is empty the data source is
## not read at all, so a pure legacy tfvars file works unchanged.
##

provider "stack" {
  api_url = var.api_url
}

data "stack_config" "this" {
  count         = var.phone_home_id != "" ? 1 : 0
  phone_home_id = var.phone_home_id
}

locals {
  # The rendered config, or null when no phone_home_id was supplied (legacy flow).
  cfg = one(data.stack_config.this)

  # identifiers — legacy var wins, else data source
  nuon_install_id = var.nuon_install_id != "" ? var.nuon_install_id : try(local.cfg.install_id, "")
  nuon_org_id     = var.nuon_org_id != "" ? var.nuon_org_id : try(local.cfg.org_id, "")
  nuon_app_id     = var.nuon_app_id != "" ? var.nuon_app_id : try(local.cfg.app_id, "")

  # runner
  runner_id      = var.runner_id != "" ? var.runner_id : try(local.cfg.runner_id, "")
  runner_api_url = var.runner_api_url != "" ? var.runner_api_url : try(local.cfg.runner_api_url, "")
  phone_home_url = var.phone_home_url != "" ? var.phone_home_url : try(local.cfg.phone_home_url, "")

  # customer-supplied region: new object, else legacy flat var, else data source
  region = coalesce(try(var.aws.region, ""), var.aws_region, try(local.cfg.aws.region, ""))

  # control-plane accounts allowed to assume the operation roles
  nuon_support_iam_role_arns = length(var.nuon_support_iam_role_arns) > 0 ? var.nuon_support_iam_role_arns : try(local.cfg.aws.nuon_support_iam_role_arns, [])

  # operation-role permissions
  provision_permissions              = length(var.provision_permissions) > 0 ? var.provision_permissions : try(local.cfg.aws.provision_permissions, [])
  provision_inline_policy_document   = var.provision_inline_policy_document != "" ? var.provision_inline_policy_document : try(local.cfg.aws.provision_inline_policy_document, "")
  provision_managed_policy_arns      = length(var.provision_managed_policy_arns) > 0 ? var.provision_managed_policy_arns : try(local.cfg.aws.provision_managed_policy_arns, [])
  maintenance_permissions            = length(var.maintenance_permissions) > 0 ? var.maintenance_permissions : try(local.cfg.aws.maintenance_permissions, [])
  maintenance_inline_policy_document = var.maintenance_inline_policy_document != "" ? var.maintenance_inline_policy_document : try(local.cfg.aws.maintenance_inline_policy_document, "")
  maintenance_managed_policy_arns    = length(var.maintenance_managed_policy_arns) > 0 ? var.maintenance_managed_policy_arns : try(local.cfg.aws.maintenance_managed_policy_arns, [])
  deprovision_permissions            = length(var.deprovision_permissions) > 0 ? var.deprovision_permissions : try(local.cfg.aws.deprovision_permissions, [])
  deprovision_inline_policy_document = var.deprovision_inline_policy_document != "" ? var.deprovision_inline_policy_document : try(local.cfg.aws.deprovision_inline_policy_document, "")
  deprovision_managed_policy_arns    = length(var.deprovision_managed_policy_arns) > 0 ? var.deprovision_managed_policy_arns : try(local.cfg.aws.deprovision_managed_policy_arns, [])

  break_glass_roles = length(var.break_glass_roles) > 0 ? var.break_glass_roles : try(local.cfg.aws.break_glass_roles, {})
  custom_roles      = length(var.custom_roles) > 0 ? var.custom_roles : try(local.cfg.aws.custom_roles, {})

  # inputs and secrets
  #
  # install_inputs and secrets layer the provider/override variables over the
  # data source (override wins). auto_generate_secrets falls back to the data
  # source when the legacy list is empty.
  auto_generate_secrets = length(var.auto_generate_secrets) > 0 ? var.auto_generate_secrets : try(local.cfg.auto_generate_secrets, [])

  install_inputs = merge(
    try(local.cfg.install_inputs, {}),
    var.install_inputs,
  )

  secret_names = toset(concat(
    keys(try(local.cfg.secrets, {})),
    keys(var.secrets),
  ))
  secrets = {
    for k in local.secret_names : k => {
      description = coalesce(try(var.secrets[k].description, null), try(local.cfg.secrets[k].description, null), "")
      required    = try(var.secrets[k].required, null) != null ? var.secrets[k].required : try(local.cfg.secrets[k].required, false)
      value       = try(var.secrets[k].value, "") != "" ? var.secrets[k].value : try(local.cfg.secrets[k].value, "")
    }
  }
}
