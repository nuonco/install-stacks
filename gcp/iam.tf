resource "google_service_account" "runner" {
  account_id   = "${substr(local.prefix, 0, 23)}-runner"
  display_name = "Nuon runner for ${local.prefix}"
}

resource "google_project_iam_member" "runner_container_admin" {
  project = var.gcp_project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_project_iam_member" "runner_compute_admin" {
  project = var.gcp_project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_project_iam_member" "runner_artifact_registry" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_project_iam_member" "runner_dns_admin" {
  project = var.gcp_project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_project_iam_member" "runner_sa_user" {
  project = var.gcp_project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_project_iam_member" "runner_security_admin" {
  project = var.gcp_project_id
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:${google_service_account.runner.email}"
}
