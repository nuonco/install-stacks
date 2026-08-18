output "project_id" {
  value = var.gcp_project_id
}

output "region" {
  value = local.region
}

output "network_name" {
  value = google_compute_network.main.name
}

output "network_id" {
  value = google_compute_network.main.id
}

output "public_subnet_name" {
  value = google_compute_subnetwork.public.name
}

output "private_subnet_name" {
  value = google_compute_subnetwork.private.name
}

output "runner_subnet_name" {
  value = google_compute_subnetwork.runner.name
}

output "runner_service_account_email" {
  value = google_service_account.runner.email
}

output "runner_service_account_unique_id" {
  value       = google_service_account.runner.unique_id
  description = "Numeric uniqueId (OIDC 'sub') of the runner service account. Used to bind federated AWS reader role trust policies."
}

output "gke_node_pool_sa_email" {
  value = var.gke_node_pool_sa_email != "" ? var.gke_node_pool_sa_email : (
    local.create_gke_node_pool_sa ? google_service_account.gke_nodes[0].email : null
  )
}

output "gke_node_pool_sa_unique_id" {
  # Only known when this stack creates the SA; null when an external email is supplied.
  value       = var.gke_node_pool_sa_email == "" && local.create_gke_node_pool_sa ? google_service_account.gke_nodes[0].unique_id : null
  description = "Numeric uniqueId (OIDC 'sub') of the GKE node pool service account."
}

output "provision_sa_email" {
  value = local.has_provision ? google_service_account.provision[0].email : null
}

output "provision_sa_unique_id" {
  value       = local.has_provision ? google_service_account.provision[0].unique_id : null
  description = "Numeric uniqueId (OIDC 'sub') of the provision service account."
}

output "maintenance_sa_email" {
  value = local.has_maintenance ? google_service_account.maintenance[0].email : null
}

output "maintenance_sa_unique_id" {
  value       = local.has_maintenance ? google_service_account.maintenance[0].unique_id : null
  description = "Numeric uniqueId (OIDC 'sub') of the maintenance service account."
}

output "deprovision_sa_email" {
  value = local.has_deprovision ? google_service_account.deprovision[0].email : null
}

output "deprovision_sa_unique_id" {
  value       = local.has_deprovision ? google_service_account.deprovision[0].unique_id : null
  description = "Numeric uniqueId (OIDC 'sub') of the deprovision service account."
}

output "break_glass_sa_emails" {
  value       = local.break_glass_sa_emails
  description = "Map of break-glass role name to service account email."
}

output "break_glass_sa_unique_ids" {
  value       = local.break_glass_sa_unique_ids
  description = "Map of break-glass role name to service account numeric uniqueId."
}

output "custom_sa_emails" {
  value       = local.custom_sa_emails
  description = "Map of custom role name to service account email."
}

output "custom_sa_unique_ids" {
  value       = local.custom_sa_unique_ids
  description = "Map of custom role name to service account numeric uniqueId."
}

output "install_inputs" {
  value       = var.install_inputs
  description = "Customer-provided install inputs passed back to Nuon."
}

output "secret_names" {
  value       = local.all_secret_names
  description = "Map of {name}_secret_name to fully qualified GCP Secret Manager resource names."
}

output "custom_nested_stacks" {
  value       = local.custom_stack_outputs
  description = "Outputs of curated custom stacks, keyed by stack name."
}

output "runner_enabled" {
  value = var.runner_enabled
}
