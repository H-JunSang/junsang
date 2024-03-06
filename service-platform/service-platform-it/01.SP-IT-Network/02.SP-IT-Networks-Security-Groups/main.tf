# Create SP-IT Common 스토리지 서브넷 정보
data "azurerm_subnet" "IT_Common_Storage_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.sp_it_common_storage_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.sp_it_common_rg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.sp_it_common_vnet}"
}
# Create SP-IT Common 서브넷 정보
data "azurerm_subnet" "IT_Common_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.sp_it_common_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.sp_it_common_rg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.sp_it_common_vnet}"
}
# Create SP-IT Common 스토리지 서브넷 ID 추출
output "IT_Common_Storage_Subnet_id" {
  value = data.azurerm_subnet.IT_Common_Storage_Subnet.id
}
# Create SP-Prod Common 서브넷 ID 추출
output "IT_Common_Subnet_id" {
  value = data.azurerm_subnet.IT_Common_Subnet.id
}
# Create SP-IT Common 스토리지 서브넷 보안 그룹
resource "azurerm_network_security_group" "IT_Common_Storage_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.sp_it_common_storage_security_group}"
  location            = local.variable.location
  resource_group_name = "${local.variable.prefix}-${local.variable.sp_it_common_rg}"
  tags = {
    Creator     = local.variable.sp_it_common_tag_creator
    Environment = local.variable.sp_it_common_tag_environment
  }

  dynamic "security_rule" {
    for_each = local.it_common_storage_security_rule # From provider.tf variable
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
# Associate NSG To 스토리지 서브넷
resource "azurerm_subnet_network_security_group_association" "IT_Common_Storage_Associate" {
  subnet_id                 = data.azurerm_subnet.IT_Common_Storage_Subnet.id # From 스토리지 서브넷 ID Output Value
  network_security_group_id = azurerm_network_security_group.IT_Common_Storage_Nsg.id # NSG ID From 스토리지 보안 그룹 리소스
}
# Create SP-Prod Common 서브넷 보안 그룹
resource "azurerm_network_security_group" "IT_Common_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.sp_it_common_security_group}"
  location            = local.variable.location
  resource_group_name = "${local.variable.prefix}-${local.variable.sp_it_common_rg}"
  tags = {
    Creator     = local.variable.sp_it_common_tag_creator
    Environment = local.variable.sp_it_common_tag_environment
  }

  dynamic "security_rule" {
    for_each = local.it_common_security_rule # From provider.tf variable
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
# Associate NSG To SP-IT Common 서브넷
resource "azurerm_subnet_network_security_group_association" "IT_Common_Associate" {
  subnet_id                 = data.azurerm_subnet.IT_Common_Subnet.id # From IT Common 서브넷 ID Output Value
  network_security_group_id = azurerm_network_security_group.IT_Common_Nsg.id # NSG ID From IT Common 보안 그룹 리소스
}