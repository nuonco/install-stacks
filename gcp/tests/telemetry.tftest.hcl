mock_provider "google" {}
mock_provider "null" {}
mock_provider "random" {}

variables {
  nuon_install_id        = "inst0000000000000000000000"
  nuon_org_id            = "org00000000000000000000000"
  nuon_app_id            = "app00000000000000000000000"
  runner_id              = "run00000000000000000000000"
  runner_api_url         = "https://api.example.com"
  runner_init_script_url = "https://example.com/init.sh"
  phone_home_url         = "https://api.example.com/phone-home"
  gcp_project_id         = "example-project"
  gcp_region             = "europe-west1"
}

run "disabled_by_default" {
  command = plan

  assert {
    condition = (
      length(google_compute_address.telemetry) == 0 &&
      length(google_compute_forwarding_rule.telemetry) == 0 &&
      length(google_compute_region_backend_service.telemetry) == 0 &&
      length(google_compute_region_health_check.telemetry) == 0 &&
      length(google_compute_firewall.telemetry_health_check) == 0
    )
    error_message = "Telemetry ingress must create no resources by default."
  }

  assert {
    condition     = output.telemetry_endpoint == "" && local.phone_home_payload.telemetry_endpoint == ""
    error_message = "Disabled telemetry must report an empty endpoint in both outputs and phone-home."
  }

  assert {
    condition     = length(google_compute_instance_group_manager.runner) == 1
    error_message = "Disabling telemetry must not disable the runner."
  }
}

run "enabled" {
  command = plan

  variables {
    enable_telemetry_ingress = true
  }

  override_resource {
    override_during = plan
    target          = google_compute_address.telemetry[0]
    values          = { address = "10.128.2.19" }
  }

  override_resource {
    override_during = plan
    target          = google_compute_network.main
    values          = { id = "projects/example-project/global/networks/install" }
  }

  override_resource {
    override_during = plan
    target          = google_compute_subnetwork.runner
    values          = { id = "projects/example-project/regions/europe-west1/subnetworks/runner" }
  }

  override_resource {
    override_during = plan
    target          = google_compute_instance_group_manager.runner[0]
    values          = { instance_group = "projects/example-project/zones/europe-west1-a/instanceGroups/runner" }
  }

  override_resource {
    override_during = plan
    target          = google_compute_region_health_check.telemetry[0]
    values          = { id = "projects/example-project/regions/europe-west1/healthChecks/telemetry" }
  }

  override_resource {
    override_during = plan
    target          = google_compute_region_backend_service.telemetry[0]
    values          = { id = "projects/example-project/regions/europe-west1/backendServices/telemetry" }
  }

  assert {
    condition     = output.telemetry_endpoint == "http://10.128.2.19:4318" && local.phone_home_payload.telemetry_endpoint == "http://10.128.2.19:4318"
    error_message = "Outputs and phone-home must publish the reserved load-balancer address as an OTLP/HTTP base URL."
  }

  assert {
    condition = (
      google_compute_address.telemetry[0].address_type == "INTERNAL" &&
      google_compute_address.telemetry[0].region == "europe-west1" &&
      google_compute_address.telemetry[0].subnetwork == "projects/example-project/regions/europe-west1/subnetworks/runner" &&
      google_compute_forwarding_rule.telemetry[0].network == "projects/example-project/global/networks/install" &&
      google_compute_forwarding_rule.telemetry[0].subnetwork == "projects/example-project/regions/europe-west1/subnetworks/runner" &&
      google_compute_forwarding_rule.telemetry[0].region == "europe-west1" &&
      google_compute_forwarding_rule.telemetry[0].load_balancing_scheme == "INTERNAL" &&
      google_compute_forwarding_rule.telemetry[0].ip_protocol == "TCP" &&
      toset(google_compute_forwarding_rule.telemetry[0].ports) == toset(["4318"]) &&
      !google_compute_forwarding_rule.telemetry[0].allow_global_access &&
      google_compute_forwarding_rule.telemetry[0].backend_service == "projects/example-project/regions/europe-west1/backendServices/telemetry"
    )
    error_message = "The frontend must be private, regional, limited to TCP/4318, and wired to the telemetry backend."
  }

  assert {
    condition = (
      google_compute_region_backend_service.telemetry[0].protocol == "TCP" &&
      google_compute_region_backend_service.telemetry[0].load_balancing_scheme == "INTERNAL" &&
      google_compute_region_backend_service.telemetry[0].region == "europe-west1" &&
      one(google_compute_region_backend_service.telemetry[0].backend).group == "projects/example-project/zones/europe-west1-a/instanceGroups/runner" &&
      one(google_compute_region_backend_service.telemetry[0].backend).balancing_mode == "CONNECTION" &&
      toset(google_compute_region_backend_service.telemetry[0].health_checks) == toset(["projects/example-project/regions/europe-west1/healthChecks/telemetry"]) &&
      google_compute_region_health_check.telemetry[0].tcp_health_check[0].port == 4318
    )
    error_message = "The load balancer must target the managed instance group and check its OTLP port."
  }

  assert {
    condition     = length(google_compute_instance_group_manager.runner[0].auto_healing_policies) == 0
    error_message = "Collector health must not trigger runner auto-healing."
  }

  assert {
    condition = (
      google_compute_firewall.telemetry_health_check[0].direction == "INGRESS" &&
      toset(google_compute_firewall.telemetry_health_check[0].source_ranges) == toset(["130.211.0.0/22", "35.191.0.0/16"]) &&
      toset(google_compute_firewall.telemetry_health_check[0].target_tags) == toset(["nuon-runner"]) &&
      contains(google_compute_instance_template.runner[0].tags, "nuon-runner") &&
      one(google_compute_firewall.telemetry_health_check[0].allow).protocol == "tcp" &&
      toset(one(google_compute_firewall.telemetry_health_check[0].allow).ports) == toset(["4318"]) &&
      toset(google_compute_firewall.allow_internal.source_ranges) == toset(["10.128.0.0/16"])
    )
    error_message = "Health-check access must target only runner TCP/4318 and preserve the existing producer source range."
  }
}

run "no_runner" {
  command = plan

  variables {
    enable_telemetry_ingress = true
    runner_enabled           = false
  }

  assert {
    condition = (
      length(google_compute_instance_group_manager.runner) == 0 &&
      length(google_compute_address.telemetry) == 0 &&
      length(google_compute_forwarding_rule.telemetry) == 0 &&
      length(google_compute_region_backend_service.telemetry) == 0 &&
      length(google_compute_region_health_check.telemetry) == 0 &&
      length(google_compute_firewall.telemetry_health_check) == 0 &&
      output.telemetry_endpoint == "" &&
      local.phone_home_payload.telemetry_endpoint == ""
    )
    error_message = "Without a runner, telemetry must create no resources and report an empty endpoint even when requested."
  }
}
