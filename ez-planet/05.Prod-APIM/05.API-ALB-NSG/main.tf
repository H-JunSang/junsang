# Create Prod APIM ALB 서브넷 정보
data "azurerm_subnet" "Shared_Prod_Apim_Alb_Subnet" {
  name                 = local.variable.prod_apim_alb_subnet
  resource_group_name  = local.variable.sharedrg
  virtual_network_name = local.variable.shared_vnet
}
#Create Prod APIM 서브넷 정보
data "azurerm_subnet" "Shared_Prod_Apim_Subnet" {
  name                 = local.variable.prod_apim_subnet
  resource_group_name  = local.variable.sharedrg
  virtual_network_name = local.variable.shared_vnet
}
# Create Prod APIM ALB 서브넷 ID 추출
output "Shared_Prod_Apim_Alb_Subnet_id" {
  value = data.azurerm_subnet.Shared_Prod_Apim_Alb_Subnet.id
}
# Create Prod APIM 서브넷 ID 추출
output "Shared_Prod_Apim_Subnet_id" {
  value = data.azurerm_subnet.Shared_Prod_Apim_Subnet.id
}
# Create Prod APIM ALB 서브넷 보안 그룹
resource "azurerm_network_security_group" "Shared_Prod_Apim_Alb_Nsg" {
  name                = local.variable.prod_apim_alb_nsg_name
  location            = local.variable.location
  resource_group_name = local.variable.sharedrg
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
    Billing-API = local.variable.billing_prod_apim_alb_tag
  }

  dynamic "security_rule" {
    for_each = local.prod_apim_alb_security_rule # From provider.tf variable
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
# Create Prod APIM 서브넷 보안 그룹
resource "azurerm_network_security_group" "Shared_Prod_Apim_Nsg" {
  name                = local.variable.prod_apim_nsg_name
  location            = local.variable.location
  resource_group_name = local.variable.sharedrg
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
    Billing-API = local.variable.billing_prod_apim_tag
  }

  dynamic "security_rule" {
    for_each = local.prod_apim_security_rule # From provider.tf variable
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
# Associate NSG To APIM ALB 서브넷
resource "azurerm_subnet_network_security_group_association" "Shared_Prod_Apim_Alb_Associate" {
  subnet_id                 = data.azurerm_subnet.Shared_Prod_Apim_Alb_Subnet.id 
  network_security_group_id = azurerm_network_security_group.Shared_Prod_Apim_Alb_Nsg.id 
}
# Associate NSG To APIM 서브넷
resource "azurerm_subnet_network_security_group_association" "Shared_Prod_Apim_Associate" {
  subnet_id                 = data.azurerm_subnet.Shared_Prod_Apim_Subnet.id 
  network_security_group_id = azurerm_network_security_group.Shared_Prod_Apim_Nsg.id 
}