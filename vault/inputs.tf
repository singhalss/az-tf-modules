variable "azure_tenant_id" {
  default     = ""
  description = "Azure Tenant ID"
}

variable "azure_application_id" {
  default     = ""
  description = "Azure application ID"
}

variable "resource_group_name" {
  default = ""
}

variable "resource_group_location" {
  default = ""
}

variable "key_vault_name" {
  default = ""
}

variable "environment_name" {
  default = ""
}

variable "network_acls" {
  default     = ""
  description = "Network prefix"
}