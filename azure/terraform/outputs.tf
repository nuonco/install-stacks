output "subscription_id" {
  value = var.azure_subscription_id
}

output "resource_group_name" {
  value = var.azure_resource_group_name
}

output "location" {
  value = local.location
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "runner_subnet_name" {
  value = azurerm_subnet.runner.name
}

output "runner_subnet_id" {
  value = azurerm_subnet.runner.id
}

output "runner_vmss_name" {
  value = azurerm_linux_virtual_machine_scale_set.runner.name
}

output "runner_principal_id" {
  value = azurerm_linux_virtual_machine_scale_set.runner.identity[0].principal_id
}

output "provision_principal_id" {
  value = local.has_provision ? azurerm_user_assigned_identity.provision[0].principal_id : null
}

output "maintenance_principal_id" {
  value = local.has_maintenance ? azurerm_user_assigned_identity.maintenance[0].principal_id : null
}

output "deprovision_principal_id" {
  value = local.has_deprovision ? azurerm_user_assigned_identity.deprovision[0].principal_id : null
}

output "break_glass_principal_ids" {
  value       = local.break_glass_principal_ids
  description = "Map of break-glass role name to managed identity principal ID."
}

output "custom_principal_ids" {
  value       = local.custom_principal_ids
  description = "Map of custom role name to managed identity principal ID."
}

output "install_inputs" {
  value       = var.install_inputs
  description = "Customer-provided install inputs passed back to Nuon."
}

output "secret_names" {
  value       = local.all_secret_names
  description = "Map of {name}_secret_name to Key Vault secret versionless IDs."
}
