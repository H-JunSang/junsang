# Shared 리소스 그룹 정보
data "azurerm_resource_group" "Shared_RG" {
  name     = "${local.variable.prefix}-${local.variable.sharedrg}"
}
# Shared 네트워크  정보
data "azurerm_virtual_network" "Shared_vNet" {
  name                = "${local.variable.prefix}-${local.variable.shared_vnet}"
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
}
# Shared 스토리지 서브넷 정보
data "azurerm_subnet" "Shared_Storage_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.shared_storage_subnet}"
  resource_group_name  = "${data.azurerm_resource_group.Shared_RG.name}"
  virtual_network_name = "${data.azurerm_virtual_network.Shared_vNet.name}"
}
# 스토리지 어카운트 생성
resource "azurerm_storage_account" "Shared_File_Storage" {
  name                          = "${local.variable.storage_prefix}${local.variable.shared_file_storage}"
  resource_group_name           = "${data.azurerm_resource_group.Shared_RG.name}"
  location                      = local.variable.location
  account_tier                  = local.variable.shared_file_storage_sku
  account_replication_type      = local.variable.shared_file_storage_type
  public_network_access_enabled = local.variable.shared_file_public_network_access_enabled
  large_file_share_enabled      = local.variable.shared_file_large_file_enabled
  account_kind                  = local.variable.shared_file_storage_kind

# 네트워크 정책
  network_rules {
    default_action             = local.variable.shared_file_default_action
    ip_rules                   = local.variable.shared_file_storage_allowed_ips
    bypass                     = local.variable.shared_file_storage_bypass
  }

  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}
# 스토리지 프라이빗 엔드포인트
resource "azurerm_private_endpoint" "Shared_File_Storage_Private_Endpoint" {
  name                        = "${local.variable.prefix}-${local.variable.shared_file_storage_endpoint}"
  location                    = local.variable.location
  resource_group_name         = "${data.azurerm_resource_group.Shared_RG.name}"
  subnet_id                   = "${data.azurerm_subnet.Shared_Storage_Subnet.id}"

  private_service_connection {
    name                           = "${local.variable.prefix}-${local.variable.shared_file_storage_private_service_connection}"
    private_connection_resource_id = azurerm_storage_account.Shared_File_Storage.id
    subresource_names              = local.variable.shared_file_storage_subresource_names
    is_manual_connection           = local.variable.shared_file_dns_is_manual_connection
  }

  private_dns_zone_group {
    name                 = "${local.variable.prefix}-${local.variable.shared_file_storage_dns_zone_group}"
    private_dns_zone_ids = [azurerm_private_dns_zone.Shared_Storage_Dns_Zone.id]
  }

  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}

resource "azurerm_private_dns_zone" "Shared_Storage_Dns_Zone" {
  name                = local.variable.shared_file_storage_dns_zone_name
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"

  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "Shared_Virtual_Network_Link" {
  name                  = "${local.variable.prefix}-${local.variable.shared_vnet_virtual_link_name}"
  resource_group_name   = "${data.azurerm_resource_group.Shared_RG.name}"
  private_dns_zone_name = azurerm_private_dns_zone.Shared_Storage_Dns_Zone.name
  virtual_network_id    = data.azurerm_virtual_network.Shared_vNet.id
}