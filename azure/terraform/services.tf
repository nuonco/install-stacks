resource "azurerm_resource_provider_registration" "enabled" {
  for_each = toset(var.services)
  name     = each.value
}
