locals {
  prefix = var.nuon_install_id
  region = var.gcp_region

  labels = {
    "nuon-install-id" = var.nuon_install_id
    "nuon-org-id"     = var.nuon_org_id
    "nuon-app-id"     = var.nuon_app_id
    "managed-by"      = "nuon"
  }
}
