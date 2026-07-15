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
  # `secrets` / `gcp.runner_api_token` attributes onto every sibling value.
  cfg_present = length(data.stack_config.this) > 0

  # identifiers — legacy var wins, else data source
  nuon_install_id = var.nuon_install_id != "" ? var.nuon_install_id : (local.cfg_present ? data.stack_config.this[0].install_id : "")
  nuon_org_id     = var.nuon_org_id != "" ? var.nuon_org_id : (local.cfg_present ? data.stack_config.this[0].org_id : "")
  nuon_app_id     = var.nuon_app_id != "" ? var.nuon_app_id : (local.cfg_present ? data.stack_config.this[0].app_id : "")

  # runner
  runner_id              = var.runner_id != "" ? var.runner_id : (local.cfg_present ? data.stack_config.this[0].runner_id : "")
  runner_api_url         = var.runner_api_url != "" ? var.runner_api_url : (local.cfg_present ? data.stack_config.this[0].runner_api_url : "")
  runner_api_token       = var.runner_api_token != "" ? var.runner_api_token : (local.cfg_present ? data.stack_config.this[0].gcp.runner_api_token : "")
  runner_init_script_url = var.runner_init_script_url != "" ? var.runner_init_script_url : (local.cfg_present ? data.stack_config.this[0].gcp.runner_init_script_url : "")
  phone_home_url         = var.phone_home_url != "" ? var.phone_home_url : (local.cfg_present ? data.stack_config.this[0].phone_home_url : "")

  # machine type: override var wins (legacy tfvars set it); else the data source
  # value when non-empty; else the platform default. The empty-guard keeps a
  # ctl-api that doesn't yet serve runner_machine_type from producing a blank type.
  runner_machine_type = (
    var.runner_machine_type != "" ? var.runner_machine_type :
    local.cfg_present && data.stack_config.this[0].gcp.runner_machine_type != "" ? data.stack_config.this[0].gcp.runner_machine_type :
    "e2-medium"
  )

  # operation-role policies (one custom role per policy) + predefined roles
  provision_policies          = length(var.provision_policies) > 0 ? var.provision_policies : (local.cfg_present ? data.stack_config.this[0].gcp.provision_policies : {})
  provision_predefined_role   = var.provision_predefined_role != "" ? var.provision_predefined_role : (local.cfg_present ? data.stack_config.this[0].gcp.provision_predefined_role : "")
  maintenance_policies        = length(var.maintenance_policies) > 0 ? var.maintenance_policies : (local.cfg_present ? data.stack_config.this[0].gcp.maintenance_policies : {})
  maintenance_predefined_role = var.maintenance_predefined_role != "" ? var.maintenance_predefined_role : (local.cfg_present ? data.stack_config.this[0].gcp.maintenance_predefined_role : "")
  deprovision_policies        = length(var.deprovision_policies) > 0 ? var.deprovision_policies : (local.cfg_present ? data.stack_config.this[0].gcp.deprovision_policies : {})
  deprovision_predefined_role = var.deprovision_predefined_role != "" ? var.deprovision_predefined_role : (local.cfg_present ? data.stack_config.this[0].gcp.deprovision_predefined_role : "")

  break_glass_roles = length(var.break_glass_roles) > 0 ? var.break_glass_roles : (local.cfg_present ? data.stack_config.this[0].gcp.break_glass_roles : {})
  custom_roles      = length(var.custom_roles) > 0 ? var.custom_roles : (local.cfg_present ? data.stack_config.this[0].gcp.custom_roles : {})

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
