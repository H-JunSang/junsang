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
  variable = yamldecode(file("Prod_APIM_Route_Table_variable.yaml"))
}
# Shared APIM 서브넷 정보
data "azurerm_subnet" "Shared_Prod_APIM_Subnet" {
  name                 = local.variable.prod_apim_subnet
  resource_group_name  = local.variable.shared_rg
  virtual_network_name = local.variable.shared_vnet
}
# Shared Prod APIM Route Table
data "azurerm_route_table" "Shared_Prod_APIM_RT" {
  name                 = local.variable.prod_shared_apim_route_table
  resource_group_name  = local.variable.shared_rg
}
# Shared APIM Endpoint 인터넷 Route 라우팅 엔트리 추가
resource "azurerm_route" "Shared_Prod_APIM_Default_Route" {
  name                   = local.variable.default_route_name
  resource_group_name    = local.variable.shared_rg
  route_table_name       = local.variable.prod_shared_apim_route_table
  address_prefix         = local.variable.default_route_address_prefix
  next_hop_type          = local.variable.default_route_next_hop_type
}
# Shared 서비스 플랫폼 프로덕션 Route 라우팅 엔트리 추가
resource "azurerm_route" "Service_Platform_Prod_Route" {
  name                   = local.variable.sp_prod_route_name
  resource_group_name    = local.variable.shared_rg
  route_table_name       = local.variable.prod_shared_apim_route_table
  address_prefix         = local.variable.sp_prod_address_prefix
  next_hop_type          = local.variable.sp_prod_next_hop_type
  next_hop_in_ip_address = local.variable.sp_prod_next_hop_in_ip_address
}