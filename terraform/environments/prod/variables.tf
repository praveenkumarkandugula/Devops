variable "location" {
  description = "Azure region for prod environment resources."
  type        = string
  default     = "eastus"
}

variable "vm_size" {
  description = "VM SKU to use for both Linux and Windows in prod."
  type        = string
  default     = "Standard_B1s"
}

variable "vm_admin_username" {
  description = "Admin username for prod VMs."
  type        = string
  default     = "azureuser"
}

variable "vm_admin_password" {
  description = "Admin password for prod VMs."
  type        = string
  sensitive   = true
}
