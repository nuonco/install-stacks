locals {
  prefix         = var.nuon_install_id
  region         = var.gcp_region
  role_id_prefix = replace(var.nuon_install_id, "-", "_")

  has_provision   = length(var.provision_permissions) > 0 || var.provision_predefined_role != ""
  has_maintenance = length(var.maintenance_permissions) > 0 || var.maintenance_predefined_role != ""
  has_deprovision = length(var.deprovision_permissions) > 0 || var.deprovision_predefined_role != ""

  has_provision_custom   = length(var.provision_permissions) > 0
  has_maintenance_custom = length(var.maintenance_permissions) > 0
  has_deprovision_custom = length(var.deprovision_permissions) > 0

  # Filter to only enabled roles
  enabled_break_glass_roles = { for k, v in var.break_glass_roles : k => v if v.enabled }
  enabled_custom_roles      = { for k, v in var.custom_roles : k => v if v.enabled }

  # Service-account ids and custom-role ids for the dynamic roles.
  #
  # GCP service-account ids are capped at 30 chars and custom-role ids at 64,
  # and neither resource type supports labels. A readable "{role}-{install_id}"
  # name cannot fit both a full role name and the install id's 23 chars of
  # entropy inside 30 chars, so the dynamic roles are named by a deterministic
  # hash of (type + install id + role key) — guaranteed unique across installs
  # sharing a project, regardless of role-name length. The legible name lives in
  # display_name / title / description (see iam.tf) so the resources stay
  # searchable. account_id rules: 6–30 chars, must start with a letter, lower
  # alnum + hyphen, no trailing hyphen — the "nc-"/"nbg-" prefix + hex satisfies
  # all of these. md5 is deterministic, so the ids are stable across applies.
  custom_account_ids = {
    for k in keys(local.enabled_custom_roles) :
    k => "nc-${substr(md5("custom/${local.prefix}/${k}"), 0, 24)}"
  }
  custom_role_ids = {
    for k in keys(local.enabled_custom_roles) :
    k => "nuon_c_${md5("custom/${local.prefix}/${k}")}"
  }
  break_glass_account_ids = {
    for k in keys(local.enabled_break_glass_roles) :
    k => "nbg-${substr(md5("break_glass/${local.prefix}/${k}"), 0, 23)}"
  }
  break_glass_role_ids = {
    for k in keys(local.enabled_break_glass_roles) :
    k => "nuon_bg_${md5("break_glass/${local.prefix}/${k}")}"
  }

  # Build secret name maps for phone-home payload
  # Format: {name}_secret_name => projects/{project}/secrets/{id}/versions/latest
  auto_generate_secret_names = {
    for k, v in google_secret_manager_secret.auto_generate :
    "${k}_secret_name" => "projects/${var.gcp_project_id}/secrets/${v.secret_id}/versions/latest"
  }
  customer_secret_names = {
    for k, v in google_secret_manager_secret.customer :
    "${k}_secret_name" => "projects/${var.gcp_project_id}/secrets/${v.secret_id}/versions/latest"
  }
  all_secret_names = merge(local.auto_generate_secret_names, local.customer_secret_names)

  create_gke_node_pool_sa = var.has_gke_node_pool && var.gke_node_pool_sa_email == ""

  labels = {
    "nuon-install-id" = var.nuon_install_id
    "nuon-org-id"     = var.nuon_org_id
    "nuon-app-id"     = var.nuon_app_id
    "managed-by"      = "nuon"
  }
}
