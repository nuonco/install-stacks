###############################################################################
# Auto-generated secrets
###############################################################################

resource "random_password" "auto_generate" {
  for_each = toset(var.auto_generate_secrets)
  length   = 63
  special  = false

  keepers = {
    secret_name = each.key
    install_id  = var.nuon_install_id
  }
}

resource "google_secret_manager_secret" "auto_generate" {
  for_each  = toset(var.auto_generate_secrets)
  secret_id = "${local.prefix}-${each.key}"
  labels    = local.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "auto_generate" {
  for_each    = toset(var.auto_generate_secrets)
  secret      = google_secret_manager_secret.auto_generate[each.key].id
  secret_data = random_password.auto_generate[each.key].result

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_secret_manager_secret_iam_member" "auto_generate_accessor" {
  for_each  = local.has_provision ? toset(var.auto_generate_secrets) : toset([])
  secret_id = google_secret_manager_secret.auto_generate[each.key].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.provision[0].email}"
}

###############################################################################
# Customer-provided secrets
###############################################################################

resource "google_secret_manager_secret" "customer" {
  for_each  = toset(nonsensitive(keys(var.secrets)))
  secret_id = "${local.prefix}-${each.key}"
  labels    = local.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "customer" {
  for_each    = toset(nonsensitive(keys(var.secrets)))
  secret      = google_secret_manager_secret.customer[each.key].id
  secret_data = var.secrets[each.key].value

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_secret_manager_secret_iam_member" "customer_accessor" {
  for_each  = local.has_provision ? toset(nonsensitive(keys(var.secrets))) : toset([])
  secret_id = google_secret_manager_secret.customer[each.key].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.provision[0].email}"
}
