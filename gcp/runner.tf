resource "google_compute_instance" "runner" {
  name         = "${local.prefix}-runner"
  machine_type = "e2-medium"
  zone         = "${local.region}-a"
  labels       = local.labels
  tags         = ["nuon-runner"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.runner.id
  }

  service_account {
    email  = google_service_account.runner.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    nuon_runner_id      = var.runner_id
    nuon_runner_api_url = var.runner_api_url
    nuon_install_id     = var.nuon_install_id
    startup-script = <<-EOT
      #!/bin/bash
      set -e
      export NUON_RUNNER_ID=${var.runner_id}
      export NUON_RUNNER_API_URL=${var.runner_api_url}
      export NUON_RUNNER_API_TOKEN=${var.runner_api_token}
      export NUON_INSTALL_ID=${var.nuon_install_id}
      curl -fsSL ${var.runner_init_script_url} | bash
    EOT
  }
}
