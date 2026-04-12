# Environment-level identifiers and common tags used by all dev resources.
locals {
  environment = "dev"
  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Workload    = "Networking"
  }
}

# Resource group boundary for all dev networking resources.
resource "azurerm_resource_group" "rg" {
  name     = "rg-network-dev"
  location = var.location
  tags     = local.tags
}

# Reusable VNet module invocation with dev-specific CIDRs and security settings.
module "vnet" {
  source = "../../modules/vnet"

  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  environment         = local.environment
  vnet_name           = "vnet-dev-eastus"
  address_space       = ["10.10.0.0/16"]

  # Subnet map keyed by logical tier.
  subnets = {
    app = {
      name              = "snet-app-dev-eastus"
      address_prefixes  = ["10.10.1.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    db = {
      name              = "snet-db-dev-eastus"
      address_prefixes  = ["10.10.2.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
    management = {
      name             = "snet-mgmt-dev-eastus"
      address_prefixes = ["10.10.3.0/24"]
    }
  }

  # Shared NSG for selected subnets in this environment.
  enable_nsg = true
  security_rules = [
    {
      name                       = "AllowVnetInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "*"
    },
    {
      name                       = "AllowHttpsFromCorp"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "Internet"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "443"
    },
    {
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      destination_port_range     = "*"
    }
  ]

  # Route table is disabled for now; can be enabled per environment later.
  enable_route_table = false
  tags               = local.tags
}

# Lowest-cost Linux VM profile for dev.
resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = "vm-linux-${local.environment}-01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = var.linux_vm_size
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password

  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.linux_vm_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = local.tags
}

# NIC for the dev Linux VM on the existing app subnet from the VNet module.
resource "azurerm_network_interface" "linux_vm_nic" {
  name                = "nic-linux-${local.environment}-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.subnet_ids["app"]
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.tags
}

# Lowest-cost Windows VM profile for dev.
resource "azurerm_windows_virtual_machine" "windows_vm" {
  name                = "vm-windows-${local.environment}-01"
  computer_name       = "windev01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = var.windows_vm_size
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  patch_mode          = "AutomaticByPlatform"

  network_interface_ids = [azurerm_network_interface.windows_vm_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition-core"
    version   = "latest"
  }

  tags = local.tags
}

# NIC for the dev Windows VM on the existing app subnet from the VNet module.
resource "azurerm_network_interface" "windows_vm_nic" {
  name                = "nic-windows-${local.environment}-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.subnet_ids["app"]
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.tags
}
