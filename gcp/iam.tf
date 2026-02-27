###############################################################################
# Runner service account
###############################################################################

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

###############################################################################
# Provision service account + custom role
###############################################################################

resource "google_service_account" "provision" {
  account_id   = "${substr(local.prefix, 0, 20)}-prov"
  display_name = "Nuon provision for ${local.prefix}"
}

resource "google_project_iam_custom_role" "provision" {
  role_id     = "${substr(local.role_id_prefix, 0, 50)}_provision"
  title       = "Nuon provision role for ${local.prefix}"
  permissions = var.provision_permissions
}

resource "google_project_iam_member" "provision_custom_role" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.provision.id
  member  = "serviceAccount:${google_service_account.provision.email}"
}

resource "google_service_account_iam_member" "provision_token_creator" {
  service_account_id = google_service_account.provision.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# Maintenance service account + custom role
###############################################################################

resource "google_service_account" "maintenance" {
  account_id   = "${substr(local.prefix, 0, 20)}-maint"
  display_name = "Nuon maintenance for ${local.prefix}"
}

resource "google_project_iam_custom_role" "maintenance" {
  role_id     = "${substr(local.role_id_prefix, 0, 47)}_maintenance"
  title       = "Nuon maintenance role for ${local.prefix}"
  permissions = var.maintenance_permissions
}

resource "google_project_iam_member" "maintenance_custom_role" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.maintenance.id
  member  = "serviceAccount:${google_service_account.maintenance.email}"
}

resource "google_service_account_iam_member" "maintenance_token_creator" {
  service_account_id = google_service_account.maintenance.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# Deprovision service account + custom role
###############################################################################

resource "google_service_account" "deprovision" {
  account_id   = "${substr(local.prefix, 0, 20)}-dep"
  display_name = "Nuon deprovision for ${local.prefix}"
}

resource "google_project_iam_custom_role" "deprovision" {
  role_id     = "${substr(local.role_id_prefix, 0, 47)}_deprovision"
  title       = "Nuon deprovision role for ${local.prefix}"
  permissions = var.deprovision_permissions
}

resource "google_project_iam_member" "deprovision_custom_role" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.deprovision.id
  member  = "serviceAccount:${google_service_account.deprovision.email}"
}

resource "google_service_account_iam_member" "deprovision_token_creator" {
  service_account_id = google_service_account.deprovision.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# Break-glass service account + custom role (conditional)
###############################################################################

resource "google_service_account" "break_glass" {
  count        = var.has_break_glass ? 1 : 0
  account_id   = "${substr(local.prefix, 0, 20)}-bg"
  display_name = "Nuon break-glass for ${local.prefix}"
}

resource "google_project_iam_custom_role" "break_glass" {
  count       = var.has_break_glass ? 1 : 0
  role_id     = "${substr(local.role_id_prefix, 0, 47)}_break_glass"
  title       = "Nuon break-glass role for ${local.prefix}"
  permissions = var.break_glass_permissions
}

resource "google_project_iam_member" "break_glass_custom_role" {
  count   = var.has_break_glass ? 1 : 0
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.break_glass[0].id
  member  = "serviceAccount:${google_service_account.break_glass[0].email}"
}

resource "google_service_account_iam_member" "break_glass_token_creator" {
  count              = var.has_break_glass ? 1 : 0
  service_account_id = google_service_account.break_glass[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}
