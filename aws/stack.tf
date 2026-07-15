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
  # Whether the stack_config data source was read (provider flow). When true,
  # non-secret values are read by indexing data.stack_config.this[0] DIRECTLY —
  # not via one()/try — so per-attribute sensitivity is preserved. Routing the
  # whole object through a function collapses the mark from the sensitive
  # `secrets` attribute onto every sibling value.
  cfg_present = length(data.stack_config.this) > 0

  # identifiers — legacy var wins, else data source
  nuon_install_id = var.nuon_install_id != "" ? var.nuon_install_id : (local.cfg_present ? data.stack_config.this[0].install_id : "")
  nuon_org_id     = var.nuon_org_id != "" ? var.nuon_org_id : (local.cfg_present ? data.stack_config.this[0].org_id : "")
  nuon_app_id     = var.nuon_app_id != "" ? var.nuon_app_id : (local.cfg_present ? data.stack_config.this[0].app_id : "")

  # runner
  runner_id      = var.runner_id != "" ? var.runner_id : (local.cfg_present ? data.stack_config.this[0].runner_id : "")
  runner_api_url = var.runner_api_url != "" ? var.runner_api_url : (local.cfg_present ? data.stack_config.this[0].runner_api_url : "")
  phone_home_url = var.phone_home_url != "" ? var.phone_home_url : (local.cfg_present ? data.stack_config.this[0].phone_home_url : "")

  # customer-supplied region: new object, else legacy flat var, else data source
  region = var.aws != null ? var.aws.region : (var.aws_region != "" ? var.aws_region : (local.cfg_present ? data.stack_config.this[0].aws.region : ""))

  # machine type from the data source (Nuon app runner config) when non-empty,
  # else the platform default (also covers a ctl-api that doesn't yet serve it).
  runner_machine_type = local.cfg_present && data.stack_config.this[0].aws.runner_machine_type != "" ? data.stack_config.this[0].aws.runner_machine_type : "t3a.medium"

  # control-plane accounts allowed to assume the operation roles
  nuon_support_iam_role_arns = length(var.nuon_support_iam_role_arns) > 0 ? var.nuon_support_iam_role_arns : (local.cfg_present ? data.stack_config.this[0].aws.nuon_support_iam_role_arns : [])

  # operation-role permissions
  provision_permissions              = length(var.provision_permissions) > 0 ? var.provision_permissions : (local.cfg_present ? data.stack_config.this[0].aws.provision_permissions : [])
  provision_inline_policy_document   = var.provision_inline_policy_document != "" ? var.provision_inline_policy_document : (local.cfg_present ? data.stack_config.this[0].aws.provision_inline_policy_document : "")
  provision_managed_policy_arns      = length(var.provision_managed_policy_arns) > 0 ? var.provision_managed_policy_arns : (local.cfg_present ? data.stack_config.this[0].aws.provision_managed_policy_arns : [])
  maintenance_permissions            = length(var.maintenance_permissions) > 0 ? var.maintenance_permissions : (local.cfg_present ? data.stack_config.this[0].aws.maintenance_permissions : [])
  maintenance_inline_policy_document = var.maintenance_inline_policy_document != "" ? var.maintenance_inline_policy_document : (local.cfg_present ? data.stack_config.this[0].aws.maintenance_inline_policy_document : "")
  maintenance_managed_policy_arns    = length(var.maintenance_managed_policy_arns) > 0 ? var.maintenance_managed_policy_arns : (local.cfg_present ? data.stack_config.this[0].aws.maintenance_managed_policy_arns : [])
  deprovision_permissions            = length(var.deprovision_permissions) > 0 ? var.deprovision_permissions : (local.cfg_present ? data.stack_config.this[0].aws.deprovision_permissions : [])
  deprovision_inline_policy_document = var.deprovision_inline_policy_document != "" ? var.deprovision_inline_policy_document : (local.cfg_present ? data.stack_config.this[0].aws.deprovision_inline_policy_document : "")
  deprovision_managed_policy_arns    = length(var.deprovision_managed_policy_arns) > 0 ? var.deprovision_managed_policy_arns : (local.cfg_present ? data.stack_config.this[0].aws.deprovision_managed_policy_arns : [])

  break_glass_roles = length(var.break_glass_roles) > 0 ? var.break_glass_roles : (local.cfg_present ? data.stack_config.this[0].aws.break_glass_roles : {})
  custom_roles      = length(var.custom_roles) > 0 ? var.custom_roles : (local.cfg_present ? data.stack_config.this[0].aws.custom_roles : {})

  # inputs and secrets
  #
  # install_inputs and secrets layer the provider/override variables over the
  # data source (override wins). auto_generate_secrets falls back to the data
  # source when the legacy list is empty.
  auto_generate_secrets = length(var.auto_generate_secrets) > 0 ? var.auto_generate_secrets : (local.cfg_present ? data.stack_config.this[0].auto_generate_secrets : [])

  install_inputs = merge(
    local.cfg_present ? data.stack_config.this[0].install_inputs : {},
    var.install_inputs,
  )

  # Secrets are genuinely sensitive; the try()-collapsed marks here are correct.
  secret_names = toset(concat(
    local.cfg_present ? keys(data.stack_config.this[0].secrets) : [],
    keys(var.secrets),
  ))
  secrets = {
    for k in local.secret_names : k => {
      description = coalesce(try(var.secrets[k].description, null), try(data.stack_config.this[0].secrets[k].description, null), "")
      required    = try(var.secrets[k].required, null) != null ? var.secrets[k].required : try(data.stack_config.this[0].secrets[k].required, false)
      value       = try(var.secrets[k].value, "") != "" ? var.secrets[k].value : try(data.stack_config.this[0].secrets[k].value, "")
    }
  }
}
