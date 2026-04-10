provider "azurerm" {
  subscription_id             = var.azure_subscription_id
  resource_provider_registrations = "none"

  features {}
}
