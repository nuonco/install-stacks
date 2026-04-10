###############################################################################
# Runner service account
###############################################################################

resource "google_service_account" "runner" {
  account_id   = "${substr(local.prefix, 0, 23)}-runner"
  display_name = "Nuon runner for ${local.prefix}"
}

resource "google_project_iam_member" "runner_owner" {
  project = var.gcp_project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# GKE node pool service account — least-privilege SA for GKE nodes
###############################################################################

resource "google_service_account" "gke_nodes" {
  count        = local.create_gke_node_pool_sa ? 1 : 0
  account_id   = "${substr(local.prefix, 0, 20)}-gke-nodes"
  display_name = "GKE node pool SA for ${local.prefix}"
}

resource "google_project_iam_member" "gke_nodes_log_writer" {
  count   = local.create_gke_node_pool_sa ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  count   = local.create_gke_node_pool_sa ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  count   = local.create_gke_node_pool_sa ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_project_iam_member" "gke_nodes_artifact_reader" {
  count   = local.create_gke_node_pool_sa ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

###############################################################################
# Provision service account + role
###############################################################################

resource "google_service_account" "provision" {
  count        = local.has_provision ? 1 : 0
  account_id   = "${substr(local.prefix, 0, 20)}-prov"
  display_name = "Nuon provision for ${local.prefix}"
}

resource "google_project_iam_custom_role" "provision" {
  count       = local.has_provision_custom ? 1 : 0
  role_id     = "${substr(local.role_id_prefix, 0, 50)}_provision"
  title       = "Nuon provision role for ${local.prefix}"
  permissions = var.provision_permissions
}

resource "google_project_iam_member" "provision_custom_role" {
  count   = local.has_provision_custom ? 1 : 0
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.provision[0].id
  member  = "serviceAccount:${google_service_account.provision[0].email}"
}

resource "google_project_iam_member" "provision_predefined_role" {
  count   = var.provision_predefined_role != "" ? 1 : 0
  project = var.gcp_project_id
  role    = var.provision_predefined_role
  member  = "serviceAccount:${google_service_account.provision[0].email}"
}

resource "google_service_account_iam_member" "provision_token_creator" {
  count              = local.has_provision ? 1 : 0
  service_account_id = google_service_account.provision[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# Maintenance service account + role
###############################################################################

resource "google_service_account" "maintenance" {
  count        = local.has_maintenance ? 1 : 0
  account_id   = "${substr(local.prefix, 0, 20)}-maint"
  display_name = "Nuon maintenance for ${local.prefix}"
}

resource "google_project_iam_custom_role" "maintenance" {
  count       = local.has_maintenance_custom ? 1 : 0
  role_id     = "${substr(local.role_id_prefix, 0, 47)}_maintenance"
  title       = "Nuon maintenance role for ${local.prefix}"
  permissions = var.maintenance_permissions
}

resource "google_project_iam_member" "maintenance_custom_role" {
  count   = local.has_maintenance_custom ? 1 : 0
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.maintenance[0].id
  member  = "serviceAccount:${google_service_account.maintenance[0].email}"
}

resource "google_project_iam_member" "maintenance_predefined_role" {
  count   = var.maintenance_predefined_role != "" ? 1 : 0
  project = var.gcp_project_id
  role    = var.maintenance_predefined_role
  member  = "serviceAccount:${google_service_account.maintenance[0].email}"
}

resource "google_service_account_iam_member" "maintenance_token_creator" {
  count              = local.has_maintenance ? 1 : 0
  service_account_id = google_service_account.maintenance[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# Deprovision service account + role
###############################################################################

resource "google_service_account" "deprovision" {
  count        = local.has_deprovision ? 1 : 0
  account_id   = "${substr(local.prefix, 0, 20)}-dep"
  display_name = "Nuon deprovision for ${local.prefix}"
}

resource "google_project_iam_custom_role" "deprovision" {
  count       = local.has_deprovision_custom ? 1 : 0
  role_id     = "${substr(local.role_id_prefix, 0, 47)}_deprovision"
  title       = "Nuon deprovision role for ${local.prefix}"
  permissions = var.deprovision_permissions
}

resource "google_project_iam_member" "deprovision_custom_role" {
  count   = local.has_deprovision_custom ? 1 : 0
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.deprovision[0].id
  member  = "serviceAccount:${google_service_account.deprovision[0].email}"
}

resource "google_project_iam_member" "deprovision_predefined_role" {
  count   = var.deprovision_predefined_role != "" ? 1 : 0
  project = var.gcp_project_id
  role    = var.deprovision_predefined_role
  member  = "serviceAccount:${google_service_account.deprovision[0].email}"
}

resource "google_service_account_iam_member" "deprovision_token_creator" {
  count              = local.has_deprovision ? 1 : 0
  service_account_id = google_service_account.deprovision[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# Break-glass service accounts + roles (dynamic, one per enabled role)
###############################################################################

resource "google_service_account" "break_glass" {
  for_each     = local.enabled_break_glass_roles
  account_id   = "${substr(local.prefix, 0, 16)}-bg-${substr(replace(each.key, "/[^a-z0-9-]/", "-"), 0, 8)}"
  display_name = "Nuon break-glass ${each.key} for ${local.prefix}"
}

resource "google_project_iam_custom_role" "break_glass" {
  for_each    = { for k, v in local.enabled_break_glass_roles : k => v if length(v.permissions) > 0 }
  role_id     = "${substr(local.role_id_prefix, 0, 40)}_bg_${substr(replace(each.key, "/[^a-zA-Z0-9_]/", "_"), 0, 20)}"
  title       = "Nuon break-glass ${each.key} for ${local.prefix}"
  permissions = each.value.permissions
}

resource "google_project_iam_member" "break_glass_custom_role" {
  for_each = { for k, v in local.enabled_break_glass_roles : k => v if length(v.permissions) > 0 }
  project  = var.gcp_project_id
  role     = google_project_iam_custom_role.break_glass[each.key].id
  member   = "serviceAccount:${google_service_account.break_glass[each.key].email}"
}

resource "google_project_iam_member" "break_glass_predefined_role" {
  for_each = { for k, v in local.enabled_break_glass_roles : k => v if v.predefined_role != "" }
  project  = var.gcp_project_id
  role     = each.value.predefined_role
  member   = "serviceAccount:${google_service_account.break_glass[each.key].email}"
}

resource "google_service_account_iam_member" "break_glass_token_creator" {
  for_each           = local.enabled_break_glass_roles
  service_account_id = google_service_account.break_glass[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# Custom service accounts + roles (dynamic, one per enabled role)
###############################################################################

resource "google_service_account" "custom" {
  for_each     = local.enabled_custom_roles
  account_id   = "${substr(local.prefix, 0, 16)}-c-${substr(replace(each.key, "/[^a-z0-9-]/", "-"), 0, 9)}"
  display_name = "Nuon custom ${each.key} for ${local.prefix}"
}

resource "google_project_iam_custom_role" "custom" {
  for_each    = { for k, v in local.enabled_custom_roles : k => v if length(v.permissions) > 0 }
  role_id     = "${substr(local.role_id_prefix, 0, 40)}_c_${substr(replace(each.key, "/[^a-zA-Z0-9_]/", "_"), 0, 20)}"
  title       = "Nuon custom ${each.key} for ${local.prefix}"
  permissions = each.value.permissions
}

resource "google_project_iam_member" "custom_custom_role" {
  for_each = { for k, v in local.enabled_custom_roles : k => v if length(v.permissions) > 0 }
  project  = var.gcp_project_id
  role     = google_project_iam_custom_role.custom[each.key].id
  member   = "serviceAccount:${google_service_account.custom[each.key].email}"
}

resource "google_project_iam_member" "custom_predefined_role" {
  for_each = { for k, v in local.enabled_custom_roles : k => v if v.predefined_role != "" }
  project  = var.gcp_project_id
  role     = each.value.predefined_role
  member   = "serviceAccount:${google_service_account.custom[each.key].email}"
}

resource "google_service_account_iam_member" "custom_token_creator" {
  for_each           = local.enabled_custom_roles
  service_account_id = google_service_account.custom[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}
