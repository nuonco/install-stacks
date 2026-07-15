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
  runner_id              = var.runner_id != "" ? var.runner_id : try(local.cfg.runner_id, "")
  runner_api_url         = var.runner_api_url != "" ? var.runner_api_url : try(local.cfg.runner_api_url, "")
  runner_api_token       = var.runner_api_token != "" ? var.runner_api_token : try(local.cfg.gcp.runner_api_token, "")
  runner_init_script_url = var.runner_init_script_url != "" ? var.runner_init_script_url : try(local.cfg.gcp.runner_init_script_url, "")
  phone_home_url         = var.phone_home_url != "" ? var.phone_home_url : try(local.cfg.phone_home_url, "")

  # operation-role policies (one custom role per policy) + predefined roles
  provision_policies          = length(var.provision_policies) > 0 ? var.provision_policies : try(local.cfg.gcp.provision_policies, {})
  provision_predefined_role   = var.provision_predefined_role != "" ? var.provision_predefined_role : try(local.cfg.gcp.provision_predefined_role, "")
  maintenance_policies        = length(var.maintenance_policies) > 0 ? var.maintenance_policies : try(local.cfg.gcp.maintenance_policies, {})
  maintenance_predefined_role = var.maintenance_predefined_role != "" ? var.maintenance_predefined_role : try(local.cfg.gcp.maintenance_predefined_role, "")
  deprovision_policies        = length(var.deprovision_policies) > 0 ? var.deprovision_policies : try(local.cfg.gcp.deprovision_policies, {})
  deprovision_predefined_role = var.deprovision_predefined_role != "" ? var.deprovision_predefined_role : try(local.cfg.gcp.deprovision_predefined_role, "")

  break_glass_roles = length(var.break_glass_roles) > 0 ? var.break_glass_roles : try(local.cfg.gcp.break_glass_roles, {})
  custom_roles      = length(var.custom_roles) > 0 ? var.custom_roles : try(local.cfg.gcp.custom_roles, {})

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
