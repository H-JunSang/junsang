# Prod 리소스 그룹 정보
data "azurerm_resource_group" "Prod_RG" {
  name     = "${local.variable.prefix}-${local.variable.prodrg}"
}
# Prod 네트워크 정보
data "azurerm_virtual_network" "Prod_vNet" {
  name                = "${local.variable.prefix}-${local.variable.prod_vnet}"
  resource_group_name = "${data.azurerm_resource_group.Prod_RG.name}"
}
# Prod Mysql Subnet
resource "azurerm_subnet" "PaaS_Prod_Mysql_Subnet" {
  address_prefixes     = local.variable.prod_mysql_subnet_prefixs
  name                 = "${local.variable.prefix}-${local.variable.prod_mysql_subnet_name}"
  resource_group_name  = "${data.azurerm_resource_group.Prod_RG.name}"
  virtual_network_name = "${data.azurerm_virtual_network.Prod_vNet.name}"

  delegation {
    name      = local.variable.delegration_name
    service_delegation {
      name    = local.variable.service_delegation_name
      actions = local.variable.actions
    }
  }
}
# Create Prod Mysql 서브넷 보안 그룹
resource "azurerm_network_security_group" "Prod_MySql_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.prod_mysql_nsg_name}"
  location            = local.variable.location
  resource_group_name = "${data.azurerm_resource_group.Prod_RG.name}"
  tags = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_tag_environment
  }

  dynamic "security_rule" {
    for_each = local.prod_mysql_security_rule # From provider.tf variable
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}
# Associate Mysql NSG to Mysql 서브넷
resource "azurerm_subnet_network_security_group_association" "Prod_MySql_Associate" {
  subnet_id                 = azurerm_subnet.PaaS_Prod_Mysql_Subnet.id 
  network_security_group_id = azurerm_network_security_group.Prod_MySql_Nsg.id 
}
# Create Mysql Private DNS zone
resource "azurerm_private_dns_zone" "Prod_MySql_Zone" {
  name                = local.variable.prod_mysql_private_dns_zone
  resource_group_name = "${data.azurerm_resource_group.Prod_RG.name}"
}
# Create Mysql Private DNS zone Virtual Network Links
resource "azurerm_private_dns_zone_virtual_network_link" "Prod_vNet_Link" {
  name                  = "${local.variable.prefix}-${local.variable.prod_mysql_private_link_name}"
  private_dns_zone_name = azurerm_private_dns_zone.Prod_MySql_Zone.name
  resource_group_name   = "${data.azurerm_resource_group.Prod_RG.name}"
  virtual_network_id    = "${data.azurerm_virtual_network.Prod_vNet.id}"
}
# Create Mysql Private DNS zone Virtual Network Links
resource "azurerm_private_dns_zone_virtual_network_link" "Mgmt_vNet_Link" {
  name                  = local.variable.laonpeople_mgmt_virutal_link
  private_dns_zone_name = azurerm_private_dns_zone.Prod_MySql_Zone.name
  resource_group_name   = "${data.azurerm_resource_group.Prod_RG.name}"
  virtual_network_id    = local.variable.laonpeople_mgmt_virtual_network_id
}
# Create the MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "Prod_MySql" {
  location                     = local.variable.location
  name                         = local.variable.prod_mysql_name
  resource_group_name          = "${data.azurerm_resource_group.Prod_RG.name}"
  administrator_login          = local.variable.admin_username
  administrator_password       = local.variable.admin_password
  backup_retention_days        = local.variable.backup_retention_days
  delegated_subnet_id          = azurerm_subnet.PaaS_Prod_Mysql_Subnet.id
  geo_redundant_backup_enabled = local.variable.geo_redundant_backup_enabled
  private_dns_zone_id          = azurerm_private_dns_zone.Prod_MySql_Zone.id
  sku_name                     = local.variable.sku_name
  version                      = local.variable.mysql_version
  zone                         = local.variable.availability_zone

  storage {
    iops                       = local.variable.storage_iops
    size_gb                    = local.variable.storage_capacity
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.Prod_vNet_Link]

  tags = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_tag_environment
    Billing-API = local.variable.billing_tag
  }
}

