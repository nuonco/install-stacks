locals {
  # Build SA email / uniqueId maps for phone-home payload
  break_glass_sa_emails     = { for k, v in google_service_account.break_glass : k => v.email }
  custom_sa_emails          = { for k, v in google_service_account.custom : k => v.email }
  break_glass_sa_unique_ids = { for k, v in google_service_account.break_glass : k => v.unique_id }
  custom_sa_unique_ids      = { for k, v in google_service_account.custom : k => v.unique_id }

  # request_type and phone_home_type are injected by the stack_phone_home
  # resource from its lifecycle and phone_home_type attribute.
  phone_home_payload = merge({
    project_id                       = var.gcp_project_id
    region                           = var.gcp_region
    network_name                     = google_compute_network.main.name
    network_id                       = google_compute_network.main.id
    public_subnet_name               = google_compute_subnetwork.public.name
    private_subnet_name              = google_compute_subnetwork.private.name
    runner_subnet_name               = google_compute_subnetwork.runner.name
    runner_service_account_email     = google_service_account.runner.email
    runner_service_account_unique_id = google_service_account.runner.unique_id
    provision_sa_email               = local.has_provision ? google_service_account.provision[0].email : ""
    provision_sa_unique_id           = local.has_provision ? google_service_account.provision[0].unique_id : ""
    maintenance_sa_email             = local.has_maintenance ? google_service_account.maintenance[0].email : ""
    maintenance_sa_unique_id         = local.has_maintenance ? google_service_account.maintenance[0].unique_id : ""
    deprovision_sa_email             = local.has_deprovision ? google_service_account.deprovision[0].email : ""
    deprovision_sa_unique_id         = local.has_deprovision ? google_service_account.deprovision[0].unique_id : ""
    break_glass_sa_emails            = local.break_glass_sa_emails
    break_glass_sa_unique_ids        = local.break_glass_sa_unique_ids
    custom_sa_emails                 = local.custom_sa_emails
    custom_sa_unique_ids             = local.custom_sa_unique_ids
    gke_node_pool_sa_email = var.gke_node_pool_sa_email != "" ? var.gke_node_pool_sa_email : (
      local.create_gke_node_pool_sa ? google_service_account.gke_nodes[0].email : ""
    )
    gke_node_pool_sa_unique_id = var.gke_node_pool_sa_email == "" && local.create_gke_node_pool_sa ? google_service_account.gke_nodes[0].unique_id : ""
    install_inputs             = local.install_inputs
  }, local.all_secret_names)
}

resource "stack_phone_home" "this" {
  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
    google_project_service.iam_credentials,
    google_project_service.cloud_resource_manager,
    google_compute_instance_group_manager.runner,
    google_service_account.runner,
    google_service_account.provision,
    google_service_account.maintenance,
    google_service_account.deprovision,
    google_service_account.break_glass,
    google_service_account.custom,
    google_service_account.gke_nodes,
    google_compute_network.main,
    google_compute_subnetwork.public,
    google_compute_subnetwork.private,
    google_compute_subnetwork.runner,
    google_secret_manager_secret_version.auto_generate,
    google_secret_manager_secret_version.customer,
  ]

  install_id      = local.nuon_install_id
  phone_home_id   = var.phone_home_id
  phone_home_type = "gcp"

  payload = jsonencode(local.phone_home_payload)
}
