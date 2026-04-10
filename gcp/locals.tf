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
