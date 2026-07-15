resource "google_compute_instance_template" "runner" {
  count = var.runner_enabled ? 1 : 0

  name_prefix  = "${local.prefix}-runner-"
  machine_type = local.runner_machine_type
  region       = local.region
  labels       = local.labels
  tags         = ["nuon-runner"]

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
    disk_size_gb = 30
    disk_type    = "pd-balanced"
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.runner.id
  }

  service_account {
    email  = google_service_account.runner.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    nuon_runner_id      = local.runner_id
    nuon_runner_api_url = local.runner_api_url
    nuon_install_id     = local.nuon_install_id
    startup-script      = <<-EOT
      #!/bin/bash
      export NUON_RUNNER_ID=${local.runner_id}
      export NUON_RUNNER_API_URL=${local.runner_api_url}
      export NUON_RUNNER_API_TOKEN=${local.runner_api_token}
      export NUON_INSTALL_ID=${local.nuon_install_id}
      # Retry the whole bootstrap until it succeeds. Transient failures
      # (apt mirror sync, network blips, etc.) shouldn't leave the runner
      # permanently unprovisioned — init.sh is idempotent.
      until curl -fsSL ${local.runner_init_script_url} | bash; do
        echo "runner bootstrap failed, retrying in 30s"
        sleep 30
      done
    EOT
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "runner" {
  count = var.runner_enabled ? 1 : 0

  name               = "${local.prefix}-runner"
  base_instance_name = "${local.prefix}-runner"
  zone               = "${local.region}-a"
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.runner[0].self_link
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 1
    max_unavailable_fixed = 0
  }
}
