data "azurerm_client_config" "current" {}

###############################################################################
# Key Vault
###############################################################################

resource "azurerm_key_vault" "main" {
  count               = length(var.auto_generate_secrets) > 0 || length(var.secrets) > 0 ? 1 : 0
  name                = substr(replace("${local.prefix}-kv", "/[^a-zA-Z0-9-]/", "-"), 0, 24)
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = local.tags

  enable_rbac_authorization = true

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

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

resource "azurerm_key_vault_secret" "auto_generate" {
  for_each     = toset(var.auto_generate_secrets)
  name         = each.key
  value        = random_password.auto_generate[each.key].result
  key_vault_id = azurerm_key_vault.main[0].id
  tags         = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

###############################################################################
# Customer-provided secrets
###############################################################################

resource "azurerm_key_vault_secret" "customer" {
  for_each     = toset(nonsensitive(keys(var.secrets)))
  name         = each.key
  value        = var.secrets[each.key].value
  key_vault_id = azurerm_key_vault.main[0].id
  tags         = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

###############################################################################
# Key Vault access for provision identity
###############################################################################

resource "azurerm_role_assignment" "provision_kv_secrets_user" {
  count                = local.has_provision && (length(var.auto_generate_secrets) > 0 || length(var.secrets) > 0) ? 1 : 0
  scope                = azurerm_key_vault.main[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.provision[0].principal_id
}
