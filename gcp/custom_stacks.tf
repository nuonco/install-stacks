# Curated custom stacks: the app config selects child modules under ./modules
# by name; outputs are phoned home under custom_nested_stacks.<key>.
variable "custom_stacks" {
  type = map(object({
    module     = string
    parameters = optional(map(string), {})
  }))
  default     = {}
  description = "Custom stacks from the app config. `module` selects a child module under ./modules."
}

module "custom_bucket" {
  source   = "./modules/bucket"
  for_each = { for k, v in var.custom_stacks : k => v if v.module == "bucket" }

  nuon_install_id = var.nuon_install_id
  name            = each.key
  gcp_project_id  = var.gcp_project_id
  gcp_region      = var.gcp_region
  parameters      = each.value.parameters
}

locals {
  custom_stack_outputs = {
    for k, m in module.custom_bucket : k => { outputs = m.outputs }
  }
}
