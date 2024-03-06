# 클라이언트 정보
data "azurerm_client_config" "current" {
}
# 구독 정보
data "azurerm_subscription" "current"{
}
# Shared 리소스 그룹 정보
data "azurerm_resource_group" "Shared_RG" {
  name     = "${local.variable.prefix}-${local.variable.sharedrg}"
}
# Prod 리소스 그룹 정보
data "azurerm_resource_group" "Prod_RG" {
  name     = "${local.variable.prefix}-${local.variable.prodrg}"
}
# Shared 네트워크  정보
data "azurerm_virtual_network" "Shared_vNet" {
  name                = "${local.variable.prefix}-${local.variable.shared_vnet}"
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
}
# Prod 네트워크 정보
data "azurerm_virtual_network" "Prod_vNet" {
  name                = "${local.variable.prefix}-${local.variable.prod_vnet}"
  resource_group_name = "${data.azurerm_resource_group.Prod_RG.name}"
}
# Shared L7 로드밸런서 서브넷 정보
data "azurerm_subnet" "Shared_Apim_Alb_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.shared_apim_alb_subnet}"
  resource_group_name  = "${data.azurerm_resource_group.Shared_RG.name}"
  virtual_network_name = "${data.azurerm_virtual_network.Shared_vNet.name}"
}
# 사용자 할당 Identity 정보
data "azurerm_user_assigned_identity" "Shared-KeyVault-MID" {
  name                = "${local.variable.prefix}-${local.variable.shared_user_managed_identity}"
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
}
# 키 볼드 리소스 생성
resource "azurerm_key_vault" "Shared_Key_Vault" {
  name                            = "${local.variable.prefix}-${local.variable.keyvault_name}"
  location                        = local.variable.location
  resource_group_name             = "${data.azurerm_resource_group.Shared_RG.name}"
  tenant_id                       = "${data.azurerm_client_config.current.tenant_id}"
  sku_name                        = local.variable.sku_name
  enabled_for_deployment          = local.variable.for_enabled_deployment
  enabled_for_disk_encryption     = local.variable.for_enabled_disk_encryption
  enabled_for_template_deployment = local.variable.for_enabled_template_deployment
  public_network_access_enabled   = local.variable.enable_public_network_access
  purge_protection_enabled        = local.variable.enable_purge_prodection
  soft_delete_retention_days      = local.variable.soft_delete_retention_days

  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }

# 네트워크 엑세스 리스트
  network_acls {
    bypass         = local.variable.firewall_bypass
    default_action = local.variable.default_action
    ip_rules       = local.variable.allowed_ips
  }
# 키 볼트 클라이언트 권한 정책
  access_policy {
    tenant_id               = "${data.azurerm_client_config.current.tenant_id}"
    object_id               = "${data.azurerm_client_config.current.object_id}"
    key_permissions         = local.variable.key_permissions
    secret_permissions      = local.variable.secret_permissions
    certificate_permissions = local.variable.certificate_permissions
  }
# 키 볼트 애플리케이션(Identity) 권한 정책
  access_policy {
    tenant_id               = "${data.azurerm_client_config.current.tenant_id}"
    object_id               = "${data.azurerm_user_assigned_identity.Shared-KeyVault-MID.principal_id}"
    key_permissions         = local.variable.key_permissions
    secret_permissions      = local.variable.secret_permissions
    certificate_permissions = local.variable.certificate_permissions
  }
}
# 키 볼트 RSA 4096 키 생성
resource "azurerm_key_vault_key" "Shared_Key_Vault_Key" {
  name         = "${local.variable.prefix}-${local.variable.key_name}"
  key_vault_id = azurerm_key_vault.Shared_Key_Vault.id
  key_type     = local.variable.key_type
  key_size     = local.variable.key_size
  key_opts     = local.variable.key_opts

# 키 로테이션 정책
  rotation_policy {
    automatic {
      time_after_creation = local.variable.key_rotation_policy
    }
    expire_after          = local.variable.key_expire_after
    notify_before_expiry  = local.variable.notify_expiry
  }

  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}
# 프라이빗 DNS 존 생성
resource "azurerm_private_dns_zone" "Shared_Key_Vault_Dns" {
  name                = local.variable.key_vault_private_dns_zone
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}
# Shared 프라이빗 네트워크 링크 생성
resource "azurerm_private_dns_zone_virtual_network_link" "Shared_Key_Vault_Network_Link" {
  name                  = "${local.variable.prefix}-${local.variable.shared_key_vault_private_link}"
  resource_group_name   = "${data.azurerm_resource_group.Shared_RG.name}"
  private_dns_zone_name = azurerm_private_dns_zone.Shared_Key_Vault_Dns.name
  virtual_network_id    = data.azurerm_virtual_network.Shared_vNet.id
}
# Prod 프라이빗 네트워크 링크 생성
resource "azurerm_private_dns_zone_virtual_network_link" "Prod_Key_Vault_Network_Link" {
  name                  = "${local.variable.prefix}-${local.variable.prod_key_vault_private_link}"
  resource_group_name   = "${data.azurerm_resource_group.Shared_RG.name}"
  private_dns_zone_name = azurerm_private_dns_zone.Shared_Key_Vault_Dns.name
  virtual_network_id    = data.azurerm_virtual_network.Prod_vNet.id
}
# 프라이빗 엔드포인트 생성
resource "azurerm_private_endpoint" "Shared_Key_Vault_Endpoint" {
  name                = "${local.variable.prefix}-${local.variable.key_vault_private_endpoint}"
  location            = local.variable.location
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
  subnet_id           = data.azurerm_subnet.Shared_Apim_Alb_Subnet.id
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }

# 프라이빗 서비스 연결 생성
  private_service_connection {
    name                           = "${local.variable.prefix}-${local.variable.key_vault_service_connection}"
    private_connection_resource_id = azurerm_key_vault.Shared_Key_Vault.id
    subresource_names              = local.variable.key_vault_subresource
    is_manual_connection           = local.variable.is_manual_connection
  }

# 프라이빗 DNS 존 그룹 생성
  private_dns_zone_group {
    name                 = "${local.variable.prefix}-${local.variable.key_vault_private_dns_zone_group}"
    private_dns_zone_ids = [azurerm_private_dns_zone.Shared_Key_Vault_Dns.id]
  }
}