variable "custom_stacks" {
  type = map(object({
    module     = string
    parameters = optional(map(string), {})
  }))
  default     = {}
  description = "Custom stacks from the app config. `module` selects a child module under ./modules."

  validation {
    condition = alltrue([
      for stack in values(var.custom_stacks) :
      contains(["bucket", "cloudsql", "dns", "kms", "service_account"], stack.module)
    ])
    error_message = "custom_stacks supports only bucket, cloudsql, dns, kms, and service_account modules."
  }
}

locals {
  custom_cloudsql_stacks = { for k, v in var.custom_stacks : k => v if v.module == "cloudsql" }
}

resource "google_compute_global_address" "private_services" {
  count = length(local.custom_cloudsql_stacks) > 0 ? 1 : 0

  project       = var.gcp_project_id
  name          = "${local.prefix}-private-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_services" {
  count = length(local.custom_cloudsql_stacks) > 0 ? 1 : 0

  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services[0].name]
  deletion_policy         = "ABANDON"

  depends_on = [google_project_service.service_networking]
}

module "custom_bucket" {
  source   = "./modules/bucket"
  for_each = { for k, v in var.custom_stacks : k => v if v.module == "bucket" }

  depends_on = [google_project_service.storage]

  nuon_install_id = var.nuon_install_id
  name            = each.key
  gcp_project_id  = var.gcp_project_id
  gcp_region      = var.gcp_region
  parameters      = each.value.parameters
}

module "custom_cloudsql" {
  source   = "./modules/cloudsql"
  for_each = local.custom_cloudsql_stacks

  depends_on = [
    google_project_service.sqladmin,
    google_service_networking_connection.private_services,
  ]

  nuon_install_id = var.nuon_install_id
  name            = each.key
  gcp_project_id  = var.gcp_project_id
  gcp_region      = var.gcp_region
  gcp_network_id  = google_compute_network.main.id
  parameters      = each.value.parameters
}

module "custom_dns" {
  source   = "./modules/dns"
  for_each = { for k, v in var.custom_stacks : k => v if v.module == "dns" }

  depends_on = [google_project_service.dns]

  nuon_install_id = var.nuon_install_id
  name            = each.key
  gcp_project_id  = var.gcp_project_id
  gcp_region      = var.gcp_region
  gcp_network_id  = google_compute_network.main.id
  parameters      = each.value.parameters
}

module "custom_kms" {
  source   = "./modules/kms"
  for_each = { for k, v in var.custom_stacks : k => v if v.module == "kms" }

  depends_on = [google_project_service.cloud_kms]

  nuon_install_id = var.nuon_install_id
  name            = each.key
  gcp_project_id  = var.gcp_project_id
  gcp_region      = var.gcp_region
  parameters      = each.value.parameters
}

module "custom_service_account" {
  source   = "./modules/service_account"
  for_each = { for k, v in var.custom_stacks : k => v if v.module == "service_account" }

  depends_on = [google_project_service.iam]

  nuon_install_id = var.nuon_install_id
  name            = each.key
  gcp_project_id  = var.gcp_project_id
  gcp_region      = var.gcp_region
  parameters      = each.value.parameters
}

locals {
  custom_stack_outputs = merge(
    { for name, stack in module.custom_bucket : name => { outputs = stack.outputs } },
    { for name, stack in module.custom_cloudsql : name => { outputs = stack.outputs } },
    { for name, stack in module.custom_dns : name => { outputs = stack.outputs } },
    { for name, stack in module.custom_kms : name => { outputs = stack.outputs } },
    { for name, stack in module.custom_service_account : name => { outputs = stack.outputs } },
  )
}
