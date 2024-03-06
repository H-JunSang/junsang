# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.85.0"
    }
  }
  backend "azurerm" {}
}
# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
variable "config" {
  description = "Configuration from config.yaml"
  type        = any
  default     = {}
}

locals {
  variable = yamldecode(file("api_alb_variable.yaml"))
}
# Shared 리소스 그룹 정보
data "azurerm_resource_group" "Shared_RG" {
  name     = "${local.variable.prefix}-${local.variable.sharedrg}"
}
# Shared 네트워크 정보
data "azurerm_virtual_network" "Shared_vNet" {
  name                = "${local.variable.prefix}-${local.variable.shared_vnet}"
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
}
# Prod APIM ALB 서브넷 정보
data "azurerm_subnet" "Prod_Apim_L7_Subnet" {
  name                 = local.variable.prod_apim_alb_subnet
  resource_group_name  = "${data.azurerm_resource_group.Shared_RG.name}"
  virtual_network_name = "${data.azurerm_virtual_network.Shared_vNet.name}"
}
# Shared 키볼트 정보
data "azurerm_key_vault" "Shared_Key_Vault" {
  name                 = local.variable.keyvault_name
  resource_group_name  = "${data.azurerm_resource_group.Shared_RG.name}"
}
# Shared Identity 정보
data "azurerm_user_assigned_identity" "Shared_Key_Vault_Identity" {
  name                 = local.variable.shared_user_managed_identity
  resource_group_name  = "${data.azurerm_resource_group.Shared_RG.name}"
}
# Shared 키볼트 인증서 정보
data "azurerm_key_vault_certificate" "PaaS_Shared_Key_Vault_Certificate" {
  name                 = local.variable.key_vault_cert_name
  key_vault_id         = "${data.azurerm_key_vault.Shared_Key_Vault.id}"
}
# Identity ID Output
output "Shared_Key_Vault_Identity_id" {
  value                = data.azurerm_user_assigned_identity.Shared_Key_Vault_Identity.id
}
# Create Prod APIM L7 로드밸런서 Public IP
resource "azurerm_public_ip" "Prod_Apim_L7_PIP" {
  name                = local.variable.prod_apim_l7_pip
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
  location            = local.variable.location
  allocation_method   = local.variable.allocate_public_ip
  sku                 = local.variable.public_ip_sku

  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
    Billing-API = local.variable.billing_prod_alb_pip_tag
  }
}
# Create Prod APIM L7 로드밸런서
resource "azurerm_application_gateway" "Prod_Apim_L7" {
  name                = local.variable.prod_apim_l7_gateway_name
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
  location            = local.variable.location
  enable_http2        = local.variable.enable_http2

# Prod APIM L7 Setting SKU
  sku {
    name              = local.variable.sku_tier
    tier              = local.variable.sku_tier
  }
# Prod APIM L7 Managed Identity
  identity {
    type                           = local.variable.user_identity_type
    identity_ids                   = [data.azurerm_user_assigned_identity.Shared_Key_Vault_Identity.id]
  }
# Prod APIM L7 Setting 오토스케일링 설정
  autoscale_configuration {
    min_capacity      = local.variable.min_capacity
    max_capacity      = local.variable.max_capacity
  }
# Prod APIM L7 로드밸런서 사설 서브넷 할당
  gateway_ip_configuration {
    name              = local.variable.prod_apim_l7_ip_name
    subnet_id         = "${data.azurerm_subnet.Prod_Apim_L7_Subnet.id}"
  }
# Prod APIM L7 로드밸런서 프론트엔드 Port 설정
  frontend_port {
    name              = local.variable.frontend_port_name
    port              = local.variable.frontend_port_name
  }
# Prod APIM L7 로드 밸런서 프론트엔트 Public IP 할당
  frontend_ip_configuration {
    name                 = local.variable.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.Prod_Apim_L7_PIP.id
  }
# Prod APIM L7 로드 밸런서 백엔드 풀 설정
  backend_address_pool {
    name                 = local.variable.backend_address_pool_name
    fqdns                = local.variable.prod_apim_backend_pool_fqdns
  }
# Prod APIM L7 로드 밸런서 백엔드 HTTP 설정
  backend_http_settings {
    name                                = local.variable.http_setting_name
    cookie_based_affinity               = local.variable.cookie_affinity
    port                                = local.variable.backend_port
    protocol                            = local.variable.backend_protocol
    request_timeout                     = local.variable.request_timeout
    pick_host_name_from_backend_address = local.variable.pick_host_name_from_backend_address
    probe_name                          = local.variable.probe_name
  }
# Prod APIM L7 인증서
  ssl_certificate {
    name                             = local.variable.key_vault_cert_name
    key_vault_secret_id              = "${data.azurerm_key_vault_certificate.PaaS_Shared_Key_Vault_Certificate.secret_id}"
}
# Prod APIM L7 로드 밸런서 리슨너 설정
  http_listener {
    name                           = local.variable.listener_name
    frontend_ip_configuration_name = local.variable.frontend_ip_configuration_name
    frontend_port_name             = local.variable.frontend_port_name
    protocol                       = local.variable.frontend_protocol
    ssl_certificate_name           = local.variable.prod_apim_alb_cert_name
  }
# Prod APIM L7 로드 밸런서 라우팅 룰 설정
  request_routing_rule {
    name                           = local.variable.routing_rule
    priority                       = local.variable.routing_priority
    rule_type                      = local.variable.routing_rule_type
    http_listener_name             = local.variable.listener_name
    backend_address_pool_name      = local.variable.backend_address_pool_name
    backend_http_settings_name     = local.variable.http_setting_name
  }
# Prod APIM L7 백엔드 상태 체크
  probe {
    name                                      = local.variable.probe_name
    protocol                                  = local.variable.probe_protocol
    interval                                  = local.variable.probe_interval
    timeout                                   = local.variable.probe_timeout
    path                                      = local.variable.probe_path
    pick_host_name_from_backend_http_settings = local.variable.probe_pick_host_name_from_backend_http_settings
    unhealthy_threshold                       = local.variable.probe_unhealty_threshold
  }
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
    Billing-API = local.variable.billing_prod_alb_tag
  }
}