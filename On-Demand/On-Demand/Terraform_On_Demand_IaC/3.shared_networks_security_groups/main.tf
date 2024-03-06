# Create Shared 쿠버네티스 서브넷 정보
data "azurerm_subnet" "Shared_K8S_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.shared_k8s_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.sharedrg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.shared_vnet}"
}
# Create Shared 스토리지 서브넷 정보
data "azurerm_subnet" "Shared_Storage_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.shared_storage_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.sharedrg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.shared_vnet}"
}
# Create Shared 쿠버네티스 L7 로드밸런서 서브넷 정보
data "azurerm_subnet" "Shared_Ingress_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.shared_ingress_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.sharedrg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.shared_vnet}"
}
# Create Shared API 게이트웨이 서브넷 정보
data "azurerm_subnet" "Shared_Apim_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.shared_apim_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.sharedrg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.shared_vnet}"
}
# Create Shared API 게이트웨이 L7 로드밸런서 서브넷 정보
data "azurerm_subnet" "Shared_Apim_Alb_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.shared_apim_alb_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.sharedrg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.shared_vnet}"
}
# Create Prod API 게이트웨이 서브넷 정보
data "azurerm_subnet" "Prod_Apim_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.prod_apim_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.sharedrg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.shared_vnet}"
}
# Create Prod API 게이트웨이 L7 로드밸런서 서브넷 정보
data "azurerm_subnet" "Prod_Apim_Alb_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.prod_apim_alb_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.sharedrg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.shared_vnet}"
}
# Create Shared 쿠버네티스 서브넷 ID 추출
output "Shared_K8S_Subnet_id" {
  value = data.azurerm_subnet.Shared_K8S_Subnet.id
}
# Create Shared 스토리지 서브넷 ID 추출
output "Shared_Storage_Subnet_id" {
  value = data.azurerm_subnet.Shared_Storage_Subnet.id
}
# Create Shared 쿠버네티스 L7 로드밸런서 서브넷 ID 추출
output "Shared_Shared_Ingress_Subnet_id" {
  value = data.azurerm_subnet.Shared_Ingress_Subnet.id
}
# Create Shared API 게이트웨이 서브넷 ID 추출
output "Shared_Shared_Apim_Subnet_id" {
  value = data.azurerm_subnet.Shared_Apim_Subnet.id
}
# Create Shared API 게이트웨이 L7 로드밸런서 서브넷 ID 추출
output "Shared_Apim_Alb_Subnet_id" {
  value = data.azurerm_subnet.Shared_Apim_Alb_Subnet.id
}
# Create Prod API 게이트웨이 서브넷 ID 추출
output "Prod_Shared_Apim_Subnet_id" {
  value = data.azurerm_subnet.Prod_Apim_Subnet.id
}
# Create Prod API 게이트웨이 L7 로드밸런서 서브넷 ID 추출
output "Prod_Apim_Alb_Subnet_id" {
  value = data.azurerm_subnet.Prod_Apim_Alb_Subnet.id
}
# Create Shared 쿠버네티스 서브넷 보안 그룹
resource "azurerm_network_security_group" "Shared_K8s_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.shared_k8s_security_group}"
  location            = local.variable.location
  resource_group_name = "${local.variable.prefix}-${local.variable.sharedrg}"
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }

  dynamic "security_rule" {
    for_each = local.shared_k8s_security_rule # From provider.tf variable
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
# Associate NSG To 쿠버네티스 서브넷
resource "azurerm_subnet_network_security_group_association" "Shared_K8S_Associate" {
  subnet_id                 = data.azurerm_subnet.Shared_K8S_Subnet.id # From 쿠버네티스 서브넷 ID Output Value
  network_security_group_id = azurerm_network_security_group.Shared_K8s_Nsg.id # NSG ID From 쿠버네티스 보안 그룹 리소스
}
# Create Shared 스토리지 서브넷 보안 그룹
resource "azurerm_network_security_group" "Shared_Storage_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.shared_storage_security_group}"
  location            = local.variable.location
  resource_group_name = "${local.variable.prefix}-${local.variable.sharedrg}"
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }


  dynamic "security_rule" {
    for_each = local.shared_storage_security_rule # From provider.tf variable
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
resource "azurerm_subnet_network_security_group_association" "Shared_Storage_Associate" {
  subnet_id                 = data.azurerm_subnet.Shared_Storage_Subnet.id # From 스토리지 서브넷 ID Output Value
  network_security_group_id = azurerm_network_security_group.Shared_Storage_Nsg.id # NSG ID From 스토리지 보안 그룹 리소스
}
# Create Shared 쿠버네티스 L7 로드밸런서 서브넷 보안 그룹
resource "azurerm_network_security_group" "Shared_Ingress_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.shared_ingress_security_group}"
  location            = local.variable.location
  resource_group_name = "${local.variable.prefix}-${local.variable.sharedrg}"
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }

  dynamic "security_rule" {
    for_each = local.shared_ingress_security_rule # From provider.tf variable
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
resource "azurerm_subnet_network_security_group_association" "Shared_Ingress_Associate" {
  subnet_id                 = data.azurerm_subnet.Shared_Ingress_Subnet.id # From L7 로드밸런서 서브넷 ID Output Value
  network_security_group_id = azurerm_network_security_group.Shared_Ingress_Nsg.id # NSG ID From L7 로드밸런서 보안 그룹 리소스
}
# Create Shared API 게이트웨이 서브넷 보안 그룹
resource "azurerm_network_security_group" "Shared_apim_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.shared_apim_security_group}"
  location            = local.variable.location
  resource_group_name = "${local.variable.prefix}-${local.variable.sharedrg}"
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }

  dynamic "security_rule" {
    for_each = local.shared_apim_security_rule # From provider.tf variable
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
# Associate NSG To Shared API 게이트웨이 서브넷
resource "azurerm_subnet_network_security_group_association" "Shared_Apim_Associate" {
  subnet_id                 = data.azurerm_subnet.Shared_Apim_Subnet.id # From API 게이트웨이 서브넷 ID Output Value
  network_security_group_id = azurerm_network_security_group.Shared_apim_Nsg.id # NSG ID From API 게이트웨이 보안 그룹 리소스
}
# Create Shared API 게이트웨이 L7 로드밸런서 서브넷 보안 그룹
resource "azurerm_network_security_group" "Shared_apim_alb_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.shared_apim_alb_security_group}"
  location            = local.variable.location
  resource_group_name = "${local.variable.prefix}-${local.variable.sharedrg}"
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }

  dynamic "security_rule" {
    for_each = local.shared_apim_alb_security_rule # From provider.tf variable
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
# Associate NSG To Shared API L7 로드밸런서 게이트웨이 서브넷
resource "azurerm_subnet_network_security_group_association" "Shared_Apim_Alb_Associate" {
  subnet_id                 = data.azurerm_subnet.Shared_Apim_Alb_Subnet.id # From API 게이트웨이 L7 로드밸런서 서브넷 ID Output Value
  network_security_group_id = azurerm_network_security_group.Shared_apim_alb_Nsg.id # NSG ID From API 게이트웨이 L7 로드밸런서 보안 그룹 리소스
}
# Create Prod API 게이트웨이 서브넷 보안 그룹
resource "azurerm_network_security_group" "Prod_apim_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.prod_apim_security_group}"
  location            = local.variable.location
  resource_group_name = "${local.variable.prefix}-${local.variable.sharedrg}"
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
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
# Associate NSG To Prod API 게이트웨이 서브넷
resource "azurerm_subnet_network_security_group_association" "Prod_Apim_Associate" {
  subnet_id                 = data.azurerm_subnet.Prod_Apim_Subnet.id # From Prod API 게이트웨이 서브넷 ID Output Value
  network_security_group_id = azurerm_network_security_group.Prod_apim_Nsg.id # NSG ID From Prod API 게이트웨이 보안 그룹 리소스
}
# Create Prod API 게이트웨이 L7 로드밸런서 서브넷 보안 그룹
resource "azurerm_network_security_group" "Prod_apim_alb_Nsg" {
  name                = "${local.variable.prefix}-${local.variable.prod_apim_alb_security_group}"
  location            = local.variable.location
  resource_group_name = "${local.variable.prefix}-${local.variable.sharedrg}"
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
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
# Associate NSG To Prod API L7 로드밸런서 게이트웨이 서브넷
resource "azurerm_subnet_network_security_group_association" "Prod_Apim_Alb_Associate" {
  subnet_id                 = data.azurerm_subnet.Prod_Apim_Alb_Subnet.id # From Prod API 게이트웨이 L7 로드밸런서 서브넷 ID Output Value
  network_security_group_id = azurerm_network_security_group.Prod_apim_alb_Nsg.id # NSG ID From Prod API 게이트웨이 L7 로드밸런서 보안 그룹 리소스
}