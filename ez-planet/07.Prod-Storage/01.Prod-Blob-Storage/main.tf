# Prod 리소스 그룹 정보
data "azurerm_resource_group" "Prod_RG" {
  name     = "${local.variable.prefix}-${local.variable.prodrg}"
}
# Prod 네트워크  정보
data "azurerm_virtual_network" "Prod_vNet" {
  name                = "${local.variable.prefix}-${local.variable.prod_vnet}"
  resource_group_name = "${data.azurerm_resource_group.Prod_RG.name}"
}
# Prod 스토리지 서브넷 정보
data "azurerm_subnet" "Prod_Common_Storage_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.prod_storage_subnet}"
  resource_group_name  = "${data.azurerm_resource_group.Prod_RG.name}"
  virtual_network_name = "${data.azurerm_virtual_network.Prod_vNet.name}"
}
# Blob NFS 스토리지 어카운트 생성
resource "azurerm_storage_account" "Prod_Common_Blob_Storage" {
  name                          = local.variable.prod_common_blob_storage
  resource_group_name           = "${data.azurerm_resource_group.Prod_RG.name}"
  location                      = local.variable.location
  account_tier                  = local.variable.prod_common_blob_storage_account_sku
  account_replication_type      = local.variable.prod_common_blob_storage_replication_type
  public_network_access_enabled = local.variable.prod_common_blob_public_network_access_enabled
  account_kind                  = local.variable.prod_common_blob_account_kind
  //is_hns_enabled                = local.variable.prod_common_blob_hierarchical_namespace_enabled
  //nfsv3_enabled                 = local.variable.prod_common_storage_nfsv3_enabled

# 네트워크 정책
  network_rules {
    default_action             = local.variable.prod_common_blob_default_action
    ip_rules                   = local.variable.prod_common_blob_allowed_ips
    bypass                     = local.variable.prod_common_blob_storage_bypass
  }

  tags = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_tag_environment
    Billing-API = local.variable.billing_storage_tag
  }
}
# 스토리지 프라이빗 엔드포인트
resource "azurerm_private_endpoint" "Prod_Common_Blob_Storage_Private_Endpoint" {
  name                        = "${local.variable.prefix}-${local.variable.prod_common_blob_endpoint_name}"
  location                    = local.variable.location
  resource_group_name         = "${data.azurerm_resource_group.Prod_RG.name}"
  subnet_id                   = "${data.azurerm_subnet.Prod_Common_Storage_Subnet.id}"

  private_service_connection {
    name                           = "${local.variable.prefix}-${local.variable.prod_common_blob_private_service_connection}"
    private_connection_resource_id = azurerm_storage_account.Prod_Common_Blob_Storage.id
    subresource_names              = local.variable.prod_common_blob_storage_subresource_names
    is_manual_connection           = local.variable.prod_common_blob_dns_is_manual_connection
  }

  private_dns_zone_group {
    name                 = "${local.variable.prefix}-${local.variable.prod_common_blob_dns_zone_group}"
    private_dns_zone_ids = [azurerm_private_dns_zone.Prod_Common_blob_Dns_Zone.id]
  }

  tags = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_tag_environment
  }
}

resource "azurerm_private_dns_zone" "Prod_Common_blob_Dns_Zone" {
  name                = local.variable.prod_common_blob_dns_zone_name
  resource_group_name = "${data.azurerm_resource_group.Prod_RG.name}"

  tags = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_tag_environment
    Billing-API = local.variable.billing_storage_dns_tag
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "Prod_Virtual_Network_Link" {
  name                  = "${local.variable.prefix}-${local.variable.prod_common_vnet_virtual_link_name}"
  resource_group_name   = "${data.azurerm_resource_group.Prod_RG.name}"
  private_dns_zone_name = azurerm_private_dns_zone.Prod_Common_blob_Dns_Zone.name
  virtual_network_id    = "${data.azurerm_virtual_network.Prod_vNet.id}"
}