locals {
  prefix = var.nuon_install_id
  region = var.aws_region

  has_provision   = length(var.provision_permissions) > 0 || length(var.provision_managed_policy_arns) > 0
  has_maintenance = length(var.maintenance_permissions) > 0 || length(var.maintenance_managed_policy_arns) > 0
  has_deprovision = length(var.deprovision_permissions) > 0 || length(var.deprovision_managed_policy_arns) > 0

  enabled_break_glass_roles = { for k, v in var.break_glass_roles : k => v if v.enabled }
  enabled_custom_roles      = { for k, v in var.custom_roles : k => v if v.enabled }

  tags = {
    "nuon-install-id" = var.nuon_install_id
    "nuon-org-id"     = var.nuon_org_id
    "nuon-app-id"     = var.nuon_app_id
    "managed-by"      = "nuon"
  }
}
