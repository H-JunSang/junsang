# Create Prod 스토리지 서브넷 정보
data "azurerm_subnet" "Prod_Storage_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.prod_storage_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.prodrg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.prod_vnet}"
}
# Create Prod 쿠버네티스 L7 로드밸런서 서브넷 정보
data "azurerm_subnet" "Prod_Ingress_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.prod_ingress_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.prodrg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.prod_vnet}"
}
# Create Prod Common 서브넷 정보
data "azurerm_subnet" "Prod_Common_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.prod_common_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.prodrg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.prod_vnet}"
}
# Create Prod Inference 서브넷 정보
data "azurerm_subnet" "Prod_Inference_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.prod_inference_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.prodrg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.prod_vnet}"
}
# Create Prod 스토리지 서브넷 ID 추출
output "Prod_Storage_Subnet_id" {
  value = data.azurerm_subnet.Prod_Storage_Subnet.id
}
# Create Prod 쿠버네티스 L7 로드밸런서 서브넷 ID 추출
output "Prod_Ingress_Subnet_id" {
  value = data.azurerm_subnet.Prod_Ingress_Subnet.id
}
# Create Prod IT Common 서브넷 ID 추출
output "Prod_Common_Subnet_id" {
  value = data.azurerm_subnet.Prod_Common_Subnet.id
}
# Create Prod IT Inference ID 추출
output "Prod_It_Inference_Subnet_id" {
  value = data.azurerm_subnet.Prod_Inference_Subnet.id
}
# Create Prod 스토리지 서브넷 보안 그룹
resource "azurerm_network_security_group" "Prod_Storage_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.prod_storage_security_group}"
  location            = local.variable.location
  resource_group_name = "${local.variable.prefix}-${local.variable.prodrg}"
  tags = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_tag_environment
    Billing-API = local.variable.prod_storage_billing_api_tag
  }

  dynamic "security_rule" {
    for_each = local.prod_storage_security_rule # From provider.tf variable
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
resource "azurerm_subnet_network_security_group_association" "Prod_Storage_Associate" {
  subnet_id                 = data.azurerm_subnet.Prod_Storage_Subnet.id # From 스토리지 서브넷 ID Output Value
  network_security_group_id = azurerm_network_security_group.Prod_Storage_Nsg.id # NSG ID From 스토리지 보안 그룹 리소스
}
# Create Prod 쿠버네티스 L7 로드밸런서 서브넷 보안 그룹
resource "azurerm_network_security_group" "Prod_Ingress_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.prod_ingress_security_group}"
  location            = local.variable.location
  resource_group_name = "${local.variable.prefix}-${local.variable.prodrg}"
  tags = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_tag_environment
    Billing-API = local.variable.prod_ingress_billing_api_tag
  }

  dynamic "security_rule" {
    for_each = local.prod_ingress_security_rule # From provider.tf variable
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
# Associate NSG To 쿠버네티스 L7 로드밸런서 서브넷
resource "azurerm_subnet_network_security_group_association" "Prod_Ingress_Associate" {
  subnet_id                 = data.azurerm_subnet.Prod_Ingress_Subnet.id # From L7 로드밸런서 서브넷 ID Output Value
  network_security_group_id = azurerm_network_security_group.Prod_Ingress_Nsg.id # NSG ID From L7 로드밸런서 보안 그룹 리소스
}
# Create Prod IT Common 서브넷 보안 그룹
resource "azurerm_network_security_group" "Prod_Common_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.prod_common_security_group}"
  location            = local.variable.location
  resource_group_name = "${local.variable.prefix}-${local.variable.prodrg}"
  tags = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_tag_environment
    Billing-API = local.variable.prod_common_billing_api_tag
  }

  dynamic "security_rule" {
    for_each = local.prod_it_common_security_rule # From provider.tf variable
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
# Associate NSG To IT Common 서브넷
resource "azurerm_subnet_network_security_group_association" "Prod_Common_Associate" {
  subnet_id                 = data.azurerm_subnet.Prod_Common_Subnet.id # From Prod IT Common 서브넷 ID Output Value
  network_security_group_id = azurerm_network_security_group.Prod_Common_Nsg.id # NSG ID From Prod IT Common 보안 그룹 리소스
}
# Create Prod IT Inference 서브넷 보안 그룹
resource "azurerm_network_security_group" "Prod_Inference_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.prod_inference_security_group}"
  location            = local.variable.location
  resource_group_name = "${local.variable.prefix}-${local.variable.prodrg}"
  tags = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_tag_environment
    Billing-API = local.variable.prod_inference_billing_api_tag
  }

  dynamic "security_rule" {
    for_each = local.prod_it_inference_security_rule # From provider.tf variable
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
# Associate NSG To IT Inference 서브넷
resource "azurerm_subnet_network_security_group_association" "Prod_Inference_Associate" {
  subnet_id                 = data.azurerm_subnet.Prod_Inference_Subnet.id # From IT Inference 서브넷 ID Output Value
  network_security_group_id = azurerm_network_security_group.Prod_Inference_Nsg.id # NSG ID From IT Inference 보안 그룹 리소스
}