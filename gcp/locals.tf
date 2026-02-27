locals {
  prefix         = var.nuon_install_id
  region         = var.gcp_region
  role_id_prefix = replace(var.nuon_install_id, "-", "_")

  has_provision    = length(var.provision_permissions) > 0 || var.provision_predefined_role != ""
  has_maintenance  = length(var.maintenance_permissions) > 0 || var.maintenance_predefined_role != ""
  has_deprovision  = length(var.deprovision_permissions) > 0 || var.deprovision_predefined_role != ""

  has_provision_custom    = length(var.provision_permissions) > 0
  has_maintenance_custom  = length(var.maintenance_permissions) > 0
  has_deprovision_custom  = length(var.deprovision_permissions) > 0

  labels = {
    "nuon-install-id" = var.nuon_install_id
    "nuon-org-id"     = var.nuon_org_id
    "nuon-app-id"     = var.nuon_app_id
    "managed-by"      = "nuon"
  }
}
