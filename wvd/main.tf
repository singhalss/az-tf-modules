data "azurerm_resource_group" "wvd_resource_group" {
  name = var.wvd_resource_group_name
}

resource "azurerm_virtual_desktop_host_pool" "wvd_host_pool" {
  name                     = var.host_pool_name
  friendly_name            = "WVD Host Pool"
  description              = "Host Pool for Windows virtual desktop (wvd)"
  resource_group_name      = data.azurerm_resource_group.wvd_resource_group.name
  location                 = data.azurerm_resource_group.wvd_resource_group.location
  type                     = var.host_pool_type
  load_balancer_type       = var.sessions_load_balancing_algorithm
  validate_environment     = true
  maximum_sessions_allowed = var.maximum_sessions_allowed
  tags = merge(
    {
      Name = var.host_pool_name
    },
    var.tags
  )
}

resource "azurerm_virtual_desktop_application_group" "wvd_app_group" {
  name                = var.app_group_name
  friendly_name       = "Windows virtual desktop (wvd) App Group"
  description         = "Windows virtual desktop (wvd) App Group"
  resource_group_name = data.azurerm_resource_group.wvd_resource_group.name
  location            = data.azurerm_resource_group.wvd_resource_group.location
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.wvd_host_pool.id
  tags = merge(
    {
      Name = var.app_group_name
    },
    var.tags
  )
}

resource "azurerm_virtual_desktop_workspace" "wvd_workspace" {
  name                = var.wvd_workspace_name
  friendly_name       = "Windows virtual desktop (wvd) Workspace"
  description         = "Windows virtual desktop (wvd) Workspace"
  resource_group_name = data.azurerm_resource_group.wvd_resource_group.name
  location            = data.azurerm_resource_group.wvd_resource_group.location
  tags = merge(
    {
      Name = var.wvd_workspace_name
    },
    var.tags
  )
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "wvd_workspace_appgroup_association" {
  workspace_id         = azurerm_virtual_desktop_workspace.wvd_workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.wvd_app_group.id
}

module "wvd_session_hosts" {
  source = "../vm"
}

resource "azurerm_virtual_machine_extension" "vmext_domainJoin" {
  count                      = "${var.domain_joined ? var.instances_count : 0}"
  name                       = "${var.virtual_machine_name}-${count.index + 1}-domainJoin"
  location                   = data.azurerm_resource_group.wvd_resource_group.location
  resource_group_name        = data.azurerm_resource_group.wvd_resource_group.name
  virtual_machine_name       = module.wvd_session_hosts.hosts.*.name[count.index]
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  lifecycle {
    ignore_changes = [
      "settings",
      "protected_settings",
    ]
  }

  settings = <<SETTINGS
    {
        "Name": "${var.domain_name}",
        "OUPath": "${var.ou_path}",
        "User": "${var.domain_user_upn}@${var.domain_name}",
        "Restart": "true",
        "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
         "Password": "${var.domain_password}"
  }
PROTECTED_SETTINGS
  tags = merge(
    {
      Name = "${var.virtual_machine_name}-${count.index + 1}-domainJoin"
    },
    var.tags
  )
}

resource "azurerm_virtual_machine_extension" "vmext_additional_session_host_dsc" {
  count                      = var.instances_count
  name                       = "${var.virtual_machine_name}${count.index + 1}-additional_session_host_dsc"
  location                   = data.azurerm_resource_group.wvd_resource_group.location
  resource_group_name        = data.azurerm_resource_group.wvd_resource_group.name
  virtual_machine_name       = module.wvd_session_hosts.hosts.*.name[count.index]
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  depends_on                 = ["azurerm_virtual_machine_extension.vmext_domainJoin"]

  settings = <<SETTINGS
{
    "modulesURL": "https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates/DSC/Configuration.zip",
    "configurationFunction": "Configuration.ps1\\RegisterSessionHost",
     "properties": {
        "TenantAdminCredentials":{
            "userName":"${var.tenant_app_id}",
            "password":"PrivateSettingsRef:tenantAdminPassword"
        },
        "RDBrokerURL":"${var.RDBrokerURL}",
        "DefinedTenantGroupName":"${var.existing_tenant_group_name}",
        "TenantName":"${var.tenant_name}",
        "HostPoolName":"${azurerm_virtual_desktop_host_pool.wvd_host_pool.name}",
        "Hours":"${var.registration_expiration_hours}",
        "isServicePrincipal":"${var.is_service_principal}",
        "AadTenantId":"${var.aad_tenant_id}"
  }
}
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
{
  "items":{
    "tenantAdminPassword":"${var.tenant_app_password}"
  }
}
PROTECTED_SETTINGS
  tags = merge(
    {
      Name = "${var.virtual_machine_name}${count.index + 1}-additional_session_host_dsc"
    },
    var.tags
  )
}