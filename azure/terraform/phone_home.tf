locals {
  # Build identity principal ID maps for phone-home payload
  break_glass_principal_ids = { for k, v in azurerm_user_assigned_identity.break_glass : k => v.principal_id }
  custom_principal_ids      = { for k, v in azurerm_user_assigned_identity.custom : k => v.principal_id }

  phone_home_payload = merge({
    request_type            = "Create"
    phone_home_type         = "azure"
    subscription_id         = var.azure_subscription_id
    resource_group_name     = var.azure_resource_group_name
    location                = var.azure_location
    vnet_name               = azurerm_virtual_network.main.name
    vnet_id                 = azurerm_virtual_network.main.id
    runner_subnet_name      = azurerm_subnet.runner.name
    runner_subnet_id        = azurerm_subnet.runner.id
    runner_vmss_name        = azurerm_linux_virtual_machine_scale_set.runner.name
    runner_principal_id     = azurerm_linux_virtual_machine_scale_set.runner.identity[0].principal_id
    provision_principal_id  = local.has_provision ? azurerm_user_assigned_identity.provision[0].principal_id : ""
    maintenance_principal_id = local.has_maintenance ? azurerm_user_assigned_identity.maintenance[0].principal_id : ""
    deprovision_principal_id = local.has_deprovision ? azurerm_user_assigned_identity.deprovision[0].principal_id : ""
    break_glass_principal_ids = local.break_glass_principal_ids
    custom_principal_ids      = local.custom_principal_ids
    install_inputs            = var.install_inputs
  }, local.all_secret_names)
}

resource "null_resource" "phone_home" {
  depends_on = [
    azurerm_linux_virtual_machine_scale_set.runner,
    azurerm_role_assignment.runner_contributor,
    azurerm_user_assigned_identity.provision,
    azurerm_user_assigned_identity.maintenance,
    azurerm_user_assigned_identity.deprovision,
    azurerm_user_assigned_identity.break_glass,
    azurerm_user_assigned_identity.custom,
    azurerm_virtual_network.main,
    azurerm_subnet.runner,
    azurerm_key_vault_secret.auto_generate,
    azurerm_key_vault_secret.customer,
  ]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -sf -X POST '${var.phone_home_url}' \
        -H 'Content-Type: application/json' \
        -d '${jsonencode(local.phone_home_payload)}'
    EOT
  }
}
