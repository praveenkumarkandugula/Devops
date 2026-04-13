# Compute effective names and target subnet sets for optional NSG/UDR associations.
locals {
  all_subnet_keys = toset(keys(var.subnets))

  nsg_target_subnet_keys = var.enable_nsg ? (
    length(var.nsg_associated_subnet_keys) > 0
    ? setsubtract(var.nsg_associated_subnet_keys, var.nsg_excluded_subnet_keys)
    : setsubtract(local.all_subnet_keys, var.nsg_excluded_subnet_keys)
  ) : toset([])

  route_table_target_subnet_keys = var.enable_route_table ? (
    length(var.route_table_associated_subnet_keys) > 0
    ? setsubtract(var.route_table_associated_subnet_keys, var.route_table_excluded_subnet_keys)
    : setsubtract(local.all_subnet_keys, var.route_table_excluded_subnet_keys)
  ) : toset([])

  nsg_name_effective         = coalesce(var.nsg_name, "nsg-${var.environment}-${var.vnet_name}")
  route_table_name_effective = coalesce(var.route_table_name, "rt-${var.environment}-${var.vnet_name}")
}

# Creates the VNet and optionally attaches an existing DDoS protection plan.
resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }
}

# Creates all subnets defined by the input map.
resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                                          = each.value.name
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.this.name
  address_prefixes                              = each.value.address_prefixes
  service_endpoints                             = each.value.service_endpoints
  private_endpoint_network_policies_enabled     = each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
}

# Optional shared NSG for subnet-level policy enforcement.
resource "azurerm_network_security_group" "this" {
  count               = var.enable_nsg ? 1 : 0
  name                = local.nsg_name_effective
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Materializes each user-provided NSG rule as a dedicated Azure resource.
resource "azurerm_network_security_rule" "this" {
  for_each = var.enable_nsg ? { for rule in var.security_rules : rule.name => rule } : {}

  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.this[0].name
  source_port_range            = try(each.value.source_port_ranges, null) == null ? try(each.value.source_port_range, "*") : null
  source_port_ranges           = try(each.value.source_port_ranges, null)
  destination_port_range       = try(each.value.destination_port_ranges, null) == null ? try(each.value.destination_port_range, "*") : null
  destination_port_ranges      = try(each.value.destination_port_ranges, null)
  source_address_prefix        = try(each.value.source_address_prefixes, null) == null ? try(each.value.source_address_prefix, "*") : null
  source_address_prefixes      = try(each.value.source_address_prefixes, null)
  destination_address_prefix   = try(each.value.destination_address_prefixes, null) == null ? try(each.value.destination_address_prefix, "*") : null
  destination_address_prefixes = try(each.value.destination_address_prefixes, null)
  description                  = try(each.value.description, null)
}

# Associates the NSG only to the computed target subnets.
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = { for key in local.nsg_target_subnet_keys : key => azurerm_subnet.this[key] }

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.this[0].id
}

# Optional route table used for custom routing.
resource "azurerm_route_table" "this" {
  count               = var.enable_route_table ? 1 : 0
  name                = local.route_table_name_effective
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Creates user-defined routes when route table support is enabled.
resource "azurerm_route" "this" {
  for_each = var.enable_route_table ? { for route in var.routes : route.name => route } : {}

  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.this[0].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = try(each.value.next_hop_in_ip_address, null)
}

# Associates the route table only to the computed target subnets.
resource "azurerm_subnet_route_table_association" "this" {
  for_each = { for key in local.route_table_target_subnet_keys : key => azurerm_subnet.this[key] }

  subnet_id      = each.value.id
  route_table_id = azurerm_route_table.this[0].id
}
