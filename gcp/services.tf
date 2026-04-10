resource "google_project_service" "enabled" {
  for_each = toset(var.services)

  project = var.gcp_project_id
  service = each.value

  disable_on_destroy = false
}
