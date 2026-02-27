resource "null_resource" "phone_home" {
  depends_on = [
    google_compute_instance.runner,
    google_service_account.runner,
    google_compute_network.main,
    google_compute_subnetwork.public,
    google_compute_subnetwork.private,
    google_compute_subnetwork.runner,
  ]

  triggers = {
    phone_home_url = var.phone_home_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -sf -X POST '${var.phone_home_url}' \
        -H 'Content-Type: application/json' \
        -d '{
          "request_type": "Create",
          "phone_home_type": "gcp",
          "project_id": "${var.gcp_project_id}",
          "region": "${var.gcp_region}",
          "network_name": "${google_compute_network.main.name}",
          "network_id": "${google_compute_network.main.id}",
          "public_subnet_name": "${google_compute_subnetwork.public.name}",
          "private_subnet_name": "${google_compute_subnetwork.private.name}",
          "runner_subnet_name": "${google_compute_subnetwork.runner.name}",
          "runner_service_account_email": "${google_service_account.runner.email}"
        }'
    EOT
  }
}
