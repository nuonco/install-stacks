##
## Nuon control-plane configuration.
##
## The install-stack config (runner details, IAM permissions, roles, install
## inputs and secrets) is read from the Nuon API via the stack_config data source
## instead of being rendered into a tfvars file. The customer supplies only the
## GCP project/region and the phone_home_id.
##

provider "stack" {
  api_url = var.api_url
}

data "stack_config" "this" {
  phone_home_id = var.phone_home_id
}

locals {
  # identifiers
  nuon_install_id = data.stack_config.this.install_id
  nuon_org_id     = data.stack_config.this.org_id
  nuon_app_id     = data.stack_config.this.app_id

  # runner
  runner_id              = data.stack_config.this.runner_id
  runner_api_url         = data.stack_config.this.runner_api_url
  runner_api_token       = data.stack_config.this.gcp.runner_api_token
  runner_init_script_url = data.stack_config.this.gcp.runner_init_script_url
  phone_home_url         = data.stack_config.this.phone_home_url

  # operation-role policies (one custom role per policy) + predefined roles
  provision_policies          = data.stack_config.this.gcp.provision_policies
  provision_predefined_role   = data.stack_config.this.gcp.provision_predefined_role
  maintenance_policies        = data.stack_config.this.gcp.maintenance_policies
  maintenance_predefined_role = data.stack_config.this.gcp.maintenance_predefined_role
  deprovision_policies        = data.stack_config.this.gcp.deprovision_policies
  deprovision_predefined_role = data.stack_config.this.gcp.deprovision_predefined_role

  break_glass_roles = data.stack_config.this.gcp.break_glass_roles
  custom_roles      = data.stack_config.this.gcp.custom_roles

  # inputs and secrets
  #
  # The stack_config data source provides the base values; the install_inputs
  # and secrets variables layer on top and win. For secrets this is also how
  # values arrive at all — the API returns metadata (required/description) but
  # not the secret value.
  auto_generate_secrets = data.stack_config.this.auto_generate_secrets

  install_inputs = merge(
    data.stack_config.this.install_inputs,
    var.install_inputs,
  )

  secret_names = toset(concat(
    keys(data.stack_config.this.secrets),
    keys(var.secrets),
  ))
  secrets = {
    for k in local.secret_names : k => {
      description = coalesce(try(var.secrets[k].description, null), try(data.stack_config.this.secrets[k].description, null), "")
      required    = try(var.secrets[k].required, null) != null ? var.secrets[k].required : try(data.stack_config.this.secrets[k].required, false)
      value       = try(var.secrets[k].value, "") != "" ? var.secrets[k].value : try(data.stack_config.this.secrets[k].value, "")
    }
  }
}
