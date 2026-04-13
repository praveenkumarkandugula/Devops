variable "location" {
  description = "Azure region for dev environment resources."
  type        = string
  default     = "eastus"
}

variable "linux_vm_size" {
  description = "VM SKU to use for the Linux VM in dev."
  type        = string
  default     = "Standard_B2s"
}

variable "windows_vm_size" {
  description = "VM SKU to use for the Windows VM in dev."
  type        = string
  default     = "Standard_B2s"
}

variable "vm_admin_username" {
  description = "Admin username for dev VMs."
  type        = string
  default     = "azureuser"
}

variable "vm_admin_password" {
  description = "Admin password for dev VMs."
  type        = string
  sensitive   = true
}
