data "azurerm_subscription" "current" {}

###############################################################################
# Runner VMSS identity — Contributor on the resource group
###############################################################################

resource "azurerm_role_assignment" "runner_contributor" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_linux_virtual_machine_scale_set.runner.identity[0].principal_id
}

###############################################################################
# Provision identity + role
###############################################################################

resource "azurerm_user_assigned_identity" "provision" {
  count               = local.has_provision ? 1 : 0
  name                = "${local.prefix}-provision"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_role_definition" "provision" {
  count       = local.has_provision_custom ? 1 : 0
  name        = "${local.prefix}-provision"
  scope       = data.azurerm_resource_group.main.id
  description = "Nuon provision role for ${local.prefix}"

  permissions {
    actions = var.provision_permissions
  }

  assignable_scopes = [data.azurerm_resource_group.main.id]
}

resource "azurerm_role_assignment" "provision_custom" {
  count              = local.has_provision_custom ? 1 : 0
  scope              = data.azurerm_resource_group.main.id
  role_definition_id = azurerm_role_definition.provision[0].role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.provision[0].principal_id
}

resource "azurerm_role_assignment" "provision_predefined" {
  count                = var.provision_predefined_role != "" ? 1 : 0
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = var.provision_predefined_role
  principal_id         = azurerm_user_assigned_identity.provision[0].principal_id
}

###############################################################################
# Maintenance identity + role
###############################################################################

resource "azurerm_user_assigned_identity" "maintenance" {
  count               = local.has_maintenance ? 1 : 0
  name                = "${local.prefix}-maintenance"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_role_definition" "maintenance" {
  count       = local.has_maintenance_custom ? 1 : 0
  name        = "${local.prefix}-maintenance"
  scope       = data.azurerm_resource_group.main.id
  description = "Nuon maintenance role for ${local.prefix}"

  permissions {
    actions = var.maintenance_permissions
  }

  assignable_scopes = [data.azurerm_resource_group.main.id]
}

resource "azurerm_role_assignment" "maintenance_custom" {
  count              = local.has_maintenance_custom ? 1 : 0
  scope              = data.azurerm_resource_group.main.id
  role_definition_id = azurerm_role_definition.maintenance[0].role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.maintenance[0].principal_id
}

resource "azurerm_role_assignment" "maintenance_predefined" {
  count                = var.maintenance_predefined_role != "" ? 1 : 0
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = var.maintenance_predefined_role
  principal_id         = azurerm_user_assigned_identity.maintenance[0].principal_id
}

###############################################################################
# Deprovision identity + role
###############################################################################

resource "azurerm_user_assigned_identity" "deprovision" {
  count               = local.has_deprovision ? 1 : 0
  name                = "${local.prefix}-deprovision"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_role_definition" "deprovision" {
  count       = local.has_deprovision_custom ? 1 : 0
  name        = "${local.prefix}-deprovision"
  scope       = data.azurerm_resource_group.main.id
  description = "Nuon deprovision role for ${local.prefix}"

  permissions {
    actions = var.deprovision_permissions
  }

  assignable_scopes = [data.azurerm_resource_group.main.id]
}

resource "azurerm_role_assignment" "deprovision_custom" {
  count              = local.has_deprovision_custom ? 1 : 0
  scope              = data.azurerm_resource_group.main.id
  role_definition_id = azurerm_role_definition.deprovision[0].role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.deprovision[0].principal_id
}

resource "azurerm_role_assignment" "deprovision_predefined" {
  count                = var.deprovision_predefined_role != "" ? 1 : 0
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = var.deprovision_predefined_role
  principal_id         = azurerm_user_assigned_identity.deprovision[0].principal_id
}

###############################################################################
# Break-glass identities + roles (dynamic, one per enabled role)
###############################################################################

resource "azurerm_user_assigned_identity" "break_glass" {
  for_each            = local.enabled_break_glass_roles
  name                = "${local.prefix}-bg-${each.key}"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_role_definition" "break_glass" {
  for_each    = { for k, v in local.enabled_break_glass_roles : k => v if length(v.permissions) > 0 }
  name        = "${local.prefix}-bg-${each.key}"
  scope       = data.azurerm_resource_group.main.id
  description = "Nuon break-glass ${each.key} for ${local.prefix}"

  permissions {
    actions = each.value.permissions
  }

  assignable_scopes = [data.azurerm_resource_group.main.id]
}

resource "azurerm_role_assignment" "break_glass_custom" {
  for_each           = { for k, v in local.enabled_break_glass_roles : k => v if length(v.permissions) > 0 }
  scope              = data.azurerm_resource_group.main.id
  role_definition_id = azurerm_role_definition.break_glass[each.key].role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.break_glass[each.key].principal_id
}

resource "azurerm_role_assignment" "break_glass_predefined" {
  for_each             = { for k, v in local.enabled_break_glass_roles : k => v if v.predefined_role != "" }
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = each.value.predefined_role
  principal_id         = azurerm_user_assigned_identity.break_glass[each.key].principal_id
}

###############################################################################
# Custom identities + roles (dynamic, one per enabled role)
###############################################################################

resource "azurerm_user_assigned_identity" "custom" {
  for_each            = local.enabled_custom_roles
  name                = "${local.prefix}-c-${each.key}"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_role_definition" "custom" {
  for_each    = { for k, v in local.enabled_custom_roles : k => v if length(v.permissions) > 0 }
  name        = "${local.prefix}-c-${each.key}"
  scope       = data.azurerm_resource_group.main.id
  description = "Nuon custom ${each.key} for ${local.prefix}"

  permissions {
    actions = each.value.permissions
  }

  assignable_scopes = [data.azurerm_resource_group.main.id]
}

resource "azurerm_role_assignment" "custom_custom" {
  for_each           = { for k, v in local.enabled_custom_roles : k => v if length(v.permissions) > 0 }
  scope              = data.azurerm_resource_group.main.id
  role_definition_id = azurerm_role_definition.custom[each.key].role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.custom[each.key].principal_id
}

resource "azurerm_role_assignment" "custom_predefined" {
  for_each             = { for k, v in local.enabled_custom_roles : k => v if v.predefined_role != "" }
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = each.value.predefined_role
  principal_id         = azurerm_user_assigned_identity.custom[each.key].principal_id
}
