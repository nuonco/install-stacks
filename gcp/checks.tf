# Require a GCP target for the active flow. Uses local.cfg_present (derived from
# phone_home_id in stack.tf) as the flow flag so the failing precondition
# surfaces only the relevant vars — not phone_home_id. Preconditions (unlike
# variable validations) show the message without a "var X is Y" value dump.
resource "terraform_data" "gcp_target" {
  lifecycle {
    # Provider flow: the gcp object is required.
    precondition {
      condition     = !local.cfg_present || var.gcp != null
      error_message = "Set gcp = { project_id = \"...\", region = \"...\" } in your tfvars."
    }
    # Legacy flow: the flat project/region vars are required.
    precondition {
      condition     = local.cfg_present || (var.gcp_project_id != "" && var.gcp_region != "")
      error_message = "Set gcp_project_id and gcp_region in your tfvars."
    }
  }
}
