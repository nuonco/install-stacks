resource "google_storage_bucket" "main" {
  project                     = var.gcp_project_id
  name                        = "${var.nuon_install_id}-${var.name}"
  location                    = lookup(var.parameters, "location", var.gcp_region)
  uniform_bucket_level_access = true
  force_destroy               = lookup(var.parameters, "force_destroy", "true") == "true"

  versioning {
    enabled = lookup(var.parameters, "versioning", "false") == "true"
  }
}
