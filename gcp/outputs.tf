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
