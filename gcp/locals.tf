locals {
  prefix = var.nuon_install_id
  region = var.gcp_region

  has_provision   = length(var.provision_policies) > 0 || length(var.provision_predefined_roles) > 0
  has_maintenance = length(var.maintenance_policies) > 0 || length(var.maintenance_predefined_roles) > 0
  has_deprovision = length(var.deprovision_policies) > 0 || length(var.deprovision_predefined_roles) > 0

  # Filter to only enabled roles
  enabled_break_glass_roles = { for k, v in var.break_glass_roles : k => v if v.enabled }
  enabled_custom_roles      = { for k, v in var.custom_roles : k => v if v.enabled }

  # Service-account ids and custom-role ids for the dynamic roles.
  #
  # GCP service-account ids are capped at 30 chars and custom-role ids at 64,
  # and neither resource type supports labels. A readable "{role}-{install_id}"
  # name cannot fit both a full role name and the install id's 23 chars of
  # entropy inside 30 chars, so the dynamic roles are named by a deterministic
  # hash of (type + install id + role key) — guaranteed unique across installs
  # sharing a project, regardless of role-name length. The legible name lives in
  # display_name / title / description (see iam.tf) so the resources stay
  # searchable. account_id rules: 6–30 chars, must start with a letter, lower
  # alnum + hyphen, no trailing hyphen — the "nc-"/"nbg-" prefix + hex satisfies
  # all of these. md5 is deterministic, so the ids are stable across applies.
  custom_account_ids = {
    for k in keys(local.enabled_custom_roles) :
    k => "nc-${substr(md5("custom/${local.prefix}/${k}"), 0, 24)}"
  }
  break_glass_account_ids = {
    for k in keys(local.enabled_break_glass_roles) :
    k => "nbg-${substr(md5("break_glass/${local.prefix}/${k}"), 0, 23)}"
  }

  # One custom role per policy, mirroring the AWS one-policy-one-attachment
  # shape. Flattened to "{role key}:{policy name}" for_each keys; role ids use
  # the same hash scheme as the account ids above.
  custom_role_policies = merge([
    for rk, rv in local.enabled_custom_roles : {
      for pk, pv in rv.policies :
      "${rk}:${pk}" => { role_key = rk, policy_name = pk, permissions = pv }
    }
  ]...)
  custom_policy_role_ids = {
    for k in keys(local.custom_role_policies) :
    k => "nuon_c_${md5("custom/${local.prefix}/${k}")}"
  }
  break_glass_role_policies = merge([
    for rk, rv in local.enabled_break_glass_roles : {
      for pk, pv in rv.policies :
      "${rk}:${pk}" => { role_key = rk, policy_name = pk, permissions = pv }
    }
  ]...)
  break_glass_policy_role_ids = {
    for k in keys(local.break_glass_role_policies) :
    k => "nuon_bg_${md5("break_glass/${local.prefix}/${k}")}"
  }

  custom_role_predefined = merge([
    for rk, rv in local.enabled_custom_roles : {
      for pr in rv.predefined_roles :
      "${rk}:${pr}" => { role_key = rk, role = pr }
    }
  ]...)
  break_glass_role_predefined = merge([
    for rk, rv in local.enabled_break_glass_roles : {
      for pr in rv.predefined_roles :
      "${rk}:${pr}" => { role_key = rk, role = pr }
    }
  ]...)

  # Build secret name maps for phone-home payload
  # Format: {name}_secret_name => projects/{project}/secrets/{id}/versions/latest
  auto_generate_secret_names = {
    for k, v in google_secret_manager_secret.auto_generate :
    "${k}_secret_name" => "projects/${var.gcp_project_id}/secrets/${v.secret_id}/versions/latest"
  }
  customer_secret_names = {
    for k, v in google_secret_manager_secret.customer :
    "${k}_secret_name" => "projects/${var.gcp_project_id}/secrets/${v.secret_id}/versions/latest"
  }
  all_secret_names = merge(local.auto_generate_secret_names, local.customer_secret_names)

  create_gke_node_pool_sa = var.has_gke_node_pool && var.gke_node_pool_sa_email == ""

  labels = {
    "nuon-install-id" = var.nuon_install_id
    "nuon-org-id"     = var.nuon_org_id
    "nuon-app-id"     = var.nuon_app_id
    "managed-by"      = "nuon"
  }
}
