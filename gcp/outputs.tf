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

output "provision_sa_email" {
  value = local.has_provision ? google_service_account.provision[0].email : null
}

output "maintenance_sa_email" {
  value = local.has_maintenance ? google_service_account.maintenance[0].email : null
}

output "deprovision_sa_email" {
  value = local.has_deprovision ? google_service_account.deprovision[0].email : null
}

output "break_glass_sa_email" {
  value = var.has_break_glass ? google_service_account.break_glass[0].email : null
}
