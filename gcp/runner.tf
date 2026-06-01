resource "google_compute_instance" "runner" {
  name         = "${local.prefix}-runner"
  machine_type = var.runner_machine_type
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
      export NUON_RUNNER_ID=${var.runner_id}
      export NUON_RUNNER_API_URL=${var.runner_api_url}
      export NUON_RUNNER_API_TOKEN=${var.runner_api_token}
      export NUON_INSTALL_ID=${var.nuon_install_id}
      # Retry the whole bootstrap until it succeeds. Transient failures
      # (apt mirror sync, network blips, etc.) shouldn't leave the runner
      # permanently unprovisioned — init.sh is idempotent.
      until curl -fsSL ${var.runner_init_script_url} | bash; do
        echo "runner bootstrap failed, retrying in 30s"
        sleep 30
      done
    EOT
  }

  lifecycle {
    replace_triggered_by = [null_resource.runner_script_trigger]
  }
}

resource "null_resource" "runner_script_trigger" {
  triggers = {
    init_script_url = var.runner_init_script_url
  }
}
