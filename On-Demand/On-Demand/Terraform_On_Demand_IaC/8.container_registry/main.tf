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
# Shared 쿠버네티스 서브넷 정보
data "azurerm_subnet" "Shared_K8S_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.shared_k8s_subnet}"
  resource_group_name  = "${data.azurerm_resource_group.Shared_RG.name}"
  virtual_network_name = "${data.azurerm_virtual_network.Shared_vNet.name}"
}
# 사용자 할당 Identity 정보
data "azurerm_user_assigned_identity" "Shared-KeyVault-MID" {
  name                = "${local.variable.prefix}-${local.variable.shared_user_managed_identity}"
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
}
# 키 볼트 정보
data "azurerm_key_vault" "Shared_Key_Vault" {
  name                = "${local.variable.prefix}-${local.variable.keyvault_name}"
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
}
# 키 볼트 키 정보
data "azurerm_key_vault_key" "Shared_Key_Vault_Key" {
  name                = "${local.variable.prefix}-${local.variable.key_name}"
  key_vault_id        = "${data.azurerm_key_vault.Shared_Key_Vault.id}"
}
# Azure 컨테이너 레지스트리 생성
resource "azurerm_container_registry" "Container_Registry" {
  name                          = local.variable.container_registry
  resource_group_name           = "${data.azurerm_resource_group.Shared_RG.name}"
  location                      = local.variable.location
  sku                           = local.variable.container_sku
  admin_enabled                 = local.variable.container_admin_enabled
  network_rule_bypass_option    = local.variable.container_rule_bypass
  public_network_access_enabled = local.variable.container_public_access

# IP 허용 정책
  dynamic "network_rule_set" {
    for_each = (length("${local.variable.container_allowed_ips}") != 0 || length("${local.variable.container_allowed_subnet_ids}") != 0) ? [1] : []
    content {
      default_action = local.variable.container_default_action
      dynamic "virtual_network" {
        for_each     = local.variable.container_allowed_subnet_ids
        content {
          action     = local.variable.container_action
          subnet_id  = virtual_network.value
        }
      }
      dynamic "ip_rule" {
        for_each     = local.variable.container_allowed_ips
        content {
          action     = local.variable.container_action
          ip_range   = ip_rule.value
        }
      }
    }
  }
# Identity 연결
  identity {
    type = local.variable.user_identity_type
    identity_ids = [
      data.azurerm_user_assigned_identity.Shared-KeyVault-MID.id
    ]
  }
# 컨네이너 암호화
  encryption {
    enabled            = local.variable.container_encryption_enabled
    key_vault_key_id   = data.azurerm_key_vault_key.Shared_Key_Vault_Key.versionless_id
    identity_client_id = data.azurerm_user_assigned_identity.Shared-KeyVault-MID.client_id
  }

  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}
# 프라이빗 DNS 존 생성
resource "azurerm_private_dns_zone" "Shared_Registry_Dns" {
  name                = local.variable.container_private_dns_zone
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}
# Shared 프라이빗 네트워크 링크 생성
resource "azurerm_private_dns_zone_virtual_network_link" "Shared_Container_Network_Link" {
  name                  = "${local.variable.prefix}-${local.variable.shared_container_private_link}"
  resource_group_name   = "${data.azurerm_resource_group.Shared_RG.name}"
  private_dns_zone_name = azurerm_private_dns_zone.Shared_Registry_Dns.name
  virtual_network_id    = data.azurerm_virtual_network.Shared_vNet.id
}
# Prod 프라이빗 네트워크 링크 생성
resource "azurerm_private_dns_zone_virtual_network_link" "Prod_Container_Network_Link" {
  name                  = "${local.variable.prefix}-${local.variable.prod_container_private_link}"
  resource_group_name   = "${data.azurerm_resource_group.Shared_RG.name}"
  private_dns_zone_name = azurerm_private_dns_zone.Shared_Registry_Dns.name
  virtual_network_id    = data.azurerm_virtual_network.Prod_vNet.id
}
# 프라이빗 엔드포인트 생성
resource "azurerm_private_endpoint" "Shared_Container_Endpoint" {
  name                = "${local.variable.prefix}-${local.variable.container_private_endpoint}"
  location            = local.variable.location
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
  subnet_id           = data.azurerm_subnet.Shared_K8S_Subnet.id
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }

# 프라이빗 서비스 연결 생성
  private_service_connection {
    name                           = "${local.variable.prefix}-${local.variable.container_service_connection}"
    private_connection_resource_id = azurerm_container_registry.Container_Registry.id
    subresource_names              = local.variable.container_subresource
    is_manual_connection           = local.variable.is_manual_connection
  }

# 프라이빗 DNS 존 그룹 생성
  private_dns_zone_group {
    name                 = "${local.variable.prefix}-${local.variable.container_private_dns_zone_group}"
    private_dns_zone_ids = [azurerm_private_dns_zone.Shared_Registry_Dns.id]
  }
}