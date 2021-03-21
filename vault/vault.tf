resource "azurerm_key_vault" "key_vault" {
  name                            = format("%s-%s", var.environment_name, var.key_vault_name)
  location                        = var.resource_group_location
  resource_group_name             = var.resource_group_name
  tenant_id                       = var.azure_tenant_id
  
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  sku_name                        = "standard"

  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = var.azure_application_id
    key_permissions = [
      "get", "list", "create", "delete",
    ]
    secret_permissions = [
      "backup", "get", "list", "recover", "restore", "set", "delete",
    ]
    storage_permissions = [
      "backup", "delete", "deletesas", "get", "getsas", "list", "listsas", "purge", "recover", "regeneratekey", "restore", "set", "setsas", "update",
    ]

    certificate_permissions = [
      "get", "list", "update", "create", "import", "delete", "recover", "backup", "restore", "deleteissuers", "getissuers", "listissuers", "managecontacts", "manageissuers", "setissuers"
    ]
  }

  dynamic "network_acls" {
    for_each = var.network_acls == null ? [] : list(var.network_acls)
    iterator = acl
    content {
      bypass                     = coalesce(acl.value.bypass, "None")
      default_action             = coalesce(acl.value.default_action, "Deny")
      ip_rules                   = acl.value.ip_rules
      virtual_network_subnet_ids = acl.value.virtual_network_subnet_ids
    }
  }

  tags = merge(map("Name", format("%s-%s-%s", var.environment_name, var.key_vault_name, "Key-Vault")))
}