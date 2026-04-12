# Core placement and naming inputs.
variable "resource_group_name" {
  description = "Name of the resource group where VNet resources are deployed."
  type        = string
}

variable "location" {
  description = "Azure region for all resources created by this module."
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name, for example dev or prod."
  type        = string
}

variable "vnet_name" {
  description = "Virtual Network name."
  type        = string
}

variable "address_space" {
  description = "VNet CIDR blocks."
  type        = list(string)
}

# Subnet model for per-tier addressing and endpoint policy toggles.
variable "subnets" {
  description = "Map of subnets to create."
  type = map(object({
    name                                          = string
    address_prefixes                              = list(string)
    service_endpoints                             = optional(list(string), [])
    private_endpoint_network_policies_enabled     = optional(bool, true)
    private_link_service_network_policies_enabled = optional(bool, true)
  }))
}

# NSG controls and optional per-subnet association targeting.
variable "enable_nsg" {
  description = "Whether to create a shared NSG for subnets."
  type        = bool
  default     = true
}

variable "nsg_name" {
  description = "Optional NSG name override."
  type        = string
  default     = null
}

variable "security_rules" {
  description = "List of NSG security rules."
  type = list(object({
    name                         = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string, "*")
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string, "*")
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string, "*")
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string, "*")
    destination_address_prefixes = optional(list(string))
    description                  = optional(string)
  }))
  default = []
}

variable "nsg_associated_subnet_keys" {
  description = "Subnet map keys to associate with NSG. Empty means all subnets except excluded ones."
  type        = set(string)
  default     = []
}

variable "nsg_excluded_subnet_keys" {
  description = "Subnet map keys excluded from NSG association."
  type        = set(string)
  default     = []
}

# Route table controls and optional per-subnet association targeting.
variable "enable_route_table" {
  description = "Whether to create a route table."
  type        = bool
  default     = false
}

variable "route_table_name" {
  description = "Optional route table name override."
  type        = string
  default     = null
}

variable "routes" {
  description = "List of user-defined routes."
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default = []
}

variable "route_table_associated_subnet_keys" {
  description = "Subnet map keys to associate with route table. Empty means all subnets except excluded ones."
  type        = set(string)
  default     = []
}

variable "route_table_excluded_subnet_keys" {
  description = "Subnet map keys excluded from route table association."
  type        = set(string)
  default     = []
}

# Optional DDoS integration for production-grade protection.
variable "enable_ddos_protection" {
  description = "Enable VNet DDoS plan association."
  type        = bool
  default     = false
}

variable "ddos_protection_plan_id" {
  description = "Existing DDoS protection plan ID when enable_ddos_protection is true."
  type        = string
  default     = null
}

# Shared resource tags for cost/governance metadata.
variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
