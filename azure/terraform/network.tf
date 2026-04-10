data "azurerm_resource_group" "main" {
  name = var.azure_resource_group_name
}

###############################################################################
# NAT Gateway
###############################################################################

resource "azurerm_public_ip" "natgw" {
  name                = "${local.prefix}-natgw-pip"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_nat_gateway" "main" {
  name                = "${local.prefix}-natgw"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku_name            = "Standard"
  tags                = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.natgw.id
}

###############################################################################
# Network Security Groups
###############################################################################

resource "azurerm_network_security_group" "public" {
  name                = "${local.prefix}-public-nsg"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_network_security_rule" "public_allow_all_inbound" {
  name                        = "Allow-All-Inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.public.name
}

resource "azurerm_network_security_group" "private" {
  name                = "${local.prefix}-private-nsg"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

###############################################################################
# Route Table
###############################################################################

resource "azurerm_route_table" "private" {
  name                          = "${local.prefix}-private-routetable"
  location                      = local.location
  resource_group_name           = data.azurerm_resource_group.main.name
  bgp_route_propagation_enabled = true
  tags                          = local.tags
}

###############################################################################
# Virtual Network
###############################################################################

resource "azurerm_virtual_network" "main" {
  name                = "${local.prefix}-vnet"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = [var.vnet_cidr]
  tags                = local.tags
}

###############################################################################
# Public Subnets
###############################################################################

resource "azurerm_subnet" "public_zone1" {
  name                 = "${local.prefix}-public-subnet-zone1"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnet_1_cidr]
}

resource "azurerm_subnet" "public_zone2" {
  name                 = "${local.prefix}-public-subnet-zone2"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnet_2_cidr]
}

resource "azurerm_subnet" "public_zone3" {
  name                 = "${local.prefix}-public-subnet-zone3"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnet_3_cidr]
}

###############################################################################
# Runner Subnet
###############################################################################

resource "azurerm_subnet" "runner" {
  name                 = "${local.prefix}-private-runner-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.runner_subnet_cidr]

  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry",
  ]
}

###############################################################################
# Private Subnets
###############################################################################

resource "azurerm_subnet" "private_zone1" {
  name                 = "${local.prefix}-private-subnet-zone1"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnet_1_cidr]

  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry",
  ]
}

resource "azurerm_subnet" "private_zone2" {
  name                 = "${local.prefix}-private-subnet-zone2"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnet_2_cidr]

  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry",
  ]
}

resource "azurerm_subnet" "private_zone3" {
  name                 = "${local.prefix}-private-subnet-zone3"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnet_3_cidr]

  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry",
  ]
}

###############################################################################
# NSG Associations
###############################################################################

resource "azurerm_subnet_network_security_group_association" "public_zone1" {
  subnet_id                 = azurerm_subnet.public_zone1.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "public_zone2" {
  subnet_id                 = azurerm_subnet.public_zone2.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "public_zone3" {
  subnet_id                 = azurerm_subnet.public_zone3.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "runner" {
  subnet_id                 = azurerm_subnet.runner.id
  network_security_group_id = azurerm_network_security_group.private.id
}

resource "azurerm_subnet_network_security_group_association" "private_zone1" {
  subnet_id                 = azurerm_subnet.private_zone1.id
  network_security_group_id = azurerm_network_security_group.private.id
}

resource "azurerm_subnet_network_security_group_association" "private_zone2" {
  subnet_id                 = azurerm_subnet.private_zone2.id
  network_security_group_id = azurerm_network_security_group.private.id
}

resource "azurerm_subnet_network_security_group_association" "private_zone3" {
  subnet_id                 = azurerm_subnet.private_zone3.id
  network_security_group_id = azurerm_network_security_group.private.id
}

###############################################################################
# NAT Gateway Associations
###############################################################################

resource "azurerm_subnet_nat_gateway_association" "public_zone1" {
  subnet_id      = azurerm_subnet.public_zone1.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

resource "azurerm_subnet_nat_gateway_association" "public_zone2" {
  subnet_id      = azurerm_subnet.public_zone2.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

resource "azurerm_subnet_nat_gateway_association" "public_zone3" {
  subnet_id      = azurerm_subnet.public_zone3.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

resource "azurerm_subnet_nat_gateway_association" "runner" {
  subnet_id      = azurerm_subnet.runner.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

resource "azurerm_subnet_nat_gateway_association" "private_zone1" {
  subnet_id      = azurerm_subnet.private_zone1.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

resource "azurerm_subnet_nat_gateway_association" "private_zone2" {
  subnet_id      = azurerm_subnet.private_zone2.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

resource "azurerm_subnet_nat_gateway_association" "private_zone3" {
  subnet_id      = azurerm_subnet.private_zone3.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

###############################################################################
# Route Table Associations (private subnets)
###############################################################################

resource "azurerm_subnet_route_table_association" "runner" {
  subnet_id      = azurerm_subnet.runner.id
  route_table_id = azurerm_route_table.private.id
}

resource "azurerm_subnet_route_table_association" "private_zone1" {
  subnet_id      = azurerm_subnet.private_zone1.id
  route_table_id = azurerm_route_table.private.id
}

resource "azurerm_subnet_route_table_association" "private_zone2" {
  subnet_id      = azurerm_subnet.private_zone2.id
  route_table_id = azurerm_route_table.private.id
}

resource "azurerm_subnet_route_table_association" "private_zone3" {
  subnet_id      = azurerm_subnet.private_zone3.id
  route_table_id = azurerm_route_table.private.id
}
