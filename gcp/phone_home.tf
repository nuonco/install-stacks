locals {
  # Build SA email maps for phone-home payload
  break_glass_sa_emails = { for k, v in google_service_account.break_glass : k => v.email }
  custom_sa_emails      = { for k, v in google_service_account.custom : k => v.email }

  phone_home_payload = merge({
    request_type                 = "Create"
    phone_home_type              = "gcp"
    project_id                   = var.gcp_project_id
    region                       = var.gcp_region
    network_name                 = google_compute_network.main.name
    network_id                   = google_compute_network.main.id
    public_subnet_name           = google_compute_subnetwork.public.name
    private_subnet_name          = google_compute_subnetwork.private.name
    runner_subnet_name           = google_compute_subnetwork.runner.name
    runner_service_account_email = google_service_account.runner.email
    provision_sa_email           = local.has_provision ? google_service_account.provision[0].email : ""
    maintenance_sa_email         = local.has_maintenance ? google_service_account.maintenance[0].email : ""
    deprovision_sa_email         = local.has_deprovision ? google_service_account.deprovision[0].email : ""
    break_glass_sa_emails        = local.break_glass_sa_emails
    custom_sa_emails             = local.custom_sa_emails
    install_inputs               = var.install_inputs
  }, local.all_secret_names)
}

resource "null_resource" "phone_home" {
  depends_on = [
    google_compute_instance.runner,
    google_service_account.runner,
    google_service_account.provision,
    google_service_account.maintenance,
    google_service_account.deprovision,
    google_service_account.break_glass,
    google_service_account.custom,
    google_compute_network.main,
    google_compute_subnetwork.public,
    google_compute_subnetwork.private,
    google_compute_subnetwork.runner,
    google_secret_manager_secret_version.auto_generate,
    google_secret_manager_secret_version.customer,
  ]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -sf -X POST '${var.phone_home_url}' \
        -H 'Content-Type: application/json' \
        -d '${jsonencode(local.phone_home_payload)}'
    EOT
  }
}
