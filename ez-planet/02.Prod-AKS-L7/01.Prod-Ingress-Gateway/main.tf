# Prod Common 리소스 그룹 정보
data "azurerm_resource_group" "Prod_Common_RG" {
  name     = "${local.variable.prefix}-${local.variable.prod_common_rg}"
}
# Prod Common 네트워크 정보
data "azurerm_virtual_network" "Prod_Common_vNet" {
  name                = "${local.variable.prefix}-${local.variable.prod_common_vnet}"
  resource_group_name = "${data.azurerm_resource_group.Prod_Common_RG.name}"
}
# Prod Common L7 로드밸런서 서브넷 정보
data "azurerm_subnet" "Prod_Common_L7_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.prod_common_ingress_subnet}"
  resource_group_name  = "${data.azurerm_resource_group.Prod_Common_RG.name}"
  virtual_network_name = "${data.azurerm_virtual_network.Prod_Common_vNet.name}"
}
# Create Prod Common K8S L7 로드밸런서 Public IP
resource "azurerm_public_ip" "Prod_Common_L7_PIP" {
  name                = "${local.variable.prefix}-${local.variable.prod_common_k8s_l7_PIP}"
  resource_group_name = "${data.azurerm_resource_group.Prod_Common_RG.name}"
  location            = local.variable.location
  allocation_method   = local.variable.allocate_public_ip
  sku                 = local.variable.public_ip_sku

  tags = {
    Creator     = local.variable.prod_common_tag_creator
    Environment = local.variable.prod_common_tag_environment
  }
}

# Create Prod Common K8S L7 로드밸런서
resource "azurerm_application_gateway" "Prod_Common_K8s_L7" {
  name                = "${local.variable.prefix}-${local.variable.prod_common_k8s_l7_gateway_name}"
  resource_group_name = "${data.azurerm_resource_group.Prod_Common_RG.name}"
  location            = local.variable.location
  enable_http2        = local.variable.enable_http2

# Prod Common K8S Setting SKU
  sku {
    name              = local.variable.sku_tier
    tier              = local.variable.sku_tier
  }

# Prod Common K8S Setting 오토스케일링 설정
  autoscale_configuration {
    min_capacity      = local.variable.min_capacity
    max_capacity      = local.variable.max_capacity
  }

# Prod Common K8S L7 로드밸런서 사설 서브넷 할당
  gateway_ip_configuration {
    name              = local.variable.prod_common_k8s_l7_ip_name
    subnet_id         = "${data.azurerm_subnet.Prod_Common_L7_Subnet.id}"
  }

# Prod Common K8S L7 로드밸런서 프론트엔드 Port 설정
  frontend_port {
    name              = local.variable.frontend_port_name
    port              = local.variable.frontend_port_name
  }

# Prod Common K8S L7 로드 밸런서 프론트엔트 Public IP 할당
  frontend_ip_configuration {
    name                 = local.variable.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.Prod_Common_L7_PIP.id
  }

# Prod Common K8S L7 로드 밸런서 백엔드 풀 설정
  backend_address_pool {
    name                 = local.variable.backend_address_pool_name
  }

# Prod Common K8S L7 로드 밸런서 백엔드 HTTP 설정
  backend_http_settings {
    name                  = local.variable.http_setting_name
    cookie_based_affinity = local.variable.cookie_affinity
    path                  = local.variable.backend_path
    port                  = local.variable.backend_port
    protocol              = local.variable.backend_protocol
    request_timeout       = local.variable.request_timeout
  }

# Prod Common K8S L7 로드 밸런서 리슨너 설정
  http_listener {
    name                           = local.variable.listener_name
    frontend_ip_configuration_name = local.variable.frontend_ip_configuration_name
    frontend_port_name             = local.variable.frontend_port_name
    protocol                       = local.variable.frontend_protocol
  }

# Prod Common K8S L7 로드 밸런서 라우팅 룰 설정
  request_routing_rule {
    name                           = local.variable.routing_rule
    priority                       = local.variable.routing_priority
    rule_type                      = local.variable.routing_rule_type
    http_listener_name             = local.variable.listener_name
    backend_address_pool_name      = local.variable.backend_address_pool_name
    backend_http_settings_name     = local.variable.http_setting_name
  }

  tags = {
    Creator     = local.variable.prod_common_tag_creator
    Environment = local.variable.prod_common_tag_environment
    Billing-API = local.variable.billing_api_tag
  }
}