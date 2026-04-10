resource "azurerm_linux_virtual_machine_scale_set" "runner" {
  name                = "${local.prefix}-vmss"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard_D2as_v5"
  instances           = 1
  overprovision       = false
  upgrade_mode        = "Manual"
  tags                = local.tags

  admin_username = "nuonadmin"

  admin_ssh_key {
    username   = "nuonadmin"
    public_key = var.runner_ssh_public_key
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 30
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${local.prefix}-nic"
    primary = true

    ip_configuration {
      name      = "${local.prefix}-ipc"
      primary   = true
      subnet_id = azurerm_subnet.runner.id
    }
  }

  custom_data = base64encode(<<-EOT
    #!/bin/bash
    set -e
    export NUON_RUNNER_ID=${var.runner_id}
    export NUON_RUNNER_API_URL=${var.runner_api_url}
    export NUON_RUNNER_API_TOKEN=${var.runner_api_token}
    export NUON_INSTALL_ID=${var.nuon_install_id}
    curl -fsSL ${var.runner_init_script_url} | bash
  EOT
  )

  lifecycle {
    replace_triggered_by = [null_resource.runner_script_trigger]
  }
}

resource "null_resource" "runner_script_trigger" {
  triggers = {
    init_script_url = var.runner_init_script_url
  }
}
