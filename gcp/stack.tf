##
## Nuon control-plane configuration.
##
## The install-stack config (runner details, IAM permissions, roles, install
## inputs and secrets) is read from the Nuon API via the nuon_stack data source
## instead of being rendered into a tfvars file. The customer supplies only the
## GCP project/region and the phone_home_id.
##

provider "nuon" {
  api_url = var.nuon_api_url
}

data "nuon_stack" "this" {
  phone_home_id = var.phone_home_id
}

locals {
  # identifiers
  nuon_install_id = data.nuon_stack.this.install_id
  nuon_org_id     = data.nuon_stack.this.org_id
  nuon_app_id     = data.nuon_stack.this.app_id

  # runner
  runner_id              = data.nuon_stack.this.runner_id
  runner_api_url         = data.nuon_stack.this.runner_api_url
  runner_api_token       = data.nuon_stack.this.gcp.runner_api_token
  runner_init_script_url = data.nuon_stack.this.gcp.runner_init_script_url
  phone_home_url         = data.nuon_stack.this.phone_home_url

  # operation-role policies (one custom role per policy) + predefined roles
  provision_policies          = data.nuon_stack.this.gcp.provision_policies
  provision_predefined_role   = data.nuon_stack.this.gcp.provision_predefined_role
  maintenance_policies        = data.nuon_stack.this.gcp.maintenance_policies
  maintenance_predefined_role = data.nuon_stack.this.gcp.maintenance_predefined_role
  deprovision_policies        = data.nuon_stack.this.gcp.deprovision_policies
  deprovision_predefined_role = data.nuon_stack.this.gcp.deprovision_predefined_role

  break_glass_roles = data.nuon_stack.this.gcp.break_glass_roles
  custom_roles      = data.nuon_stack.this.gcp.custom_roles

  # inputs and secrets
  install_inputs        = data.nuon_stack.this.install_inputs
  auto_generate_secrets = data.nuon_stack.this.auto_generate_secrets
  secrets               = data.nuon_stack.this.secrets
}
