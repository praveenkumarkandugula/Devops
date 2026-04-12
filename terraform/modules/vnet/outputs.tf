output "vnet_id" {
  description = "Virtual Network resource ID."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual Network name."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet IDs by subnet key."
  value       = { for key, subnet in azurerm_subnet.this : key => subnet.id }
}

output "subnet_names" {
  description = "Map of subnet names by subnet key."
  value       = { for key, subnet in azurerm_subnet.this : key => subnet.name }
}

output "nsg_id" {
  description = "NSG ID when NSG is enabled."
  value       = var.enable_nsg ? azurerm_network_security_group.this[0].id : null
}

output "route_table_id" {
  description = "Route table ID when route table is enabled."
  value       = var.enable_route_table ? azurerm_route_table.this[0].id : null
}
