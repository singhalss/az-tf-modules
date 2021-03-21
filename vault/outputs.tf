output "key_vault_url" {
  value       = azurerm_key_vault.key_vault.vault_uri
  description = "Key Vault URL."
  depends_on = [
    azurerm_key_vault.key_vault,
  ]
}

output "key_vault_resource_id" {
  value       = azurerm_key_vault.key_vault.id
  description = "Key vault resource ID."
  depends_on = [
    azurerm_key_vault.key_vault,
  ]
}