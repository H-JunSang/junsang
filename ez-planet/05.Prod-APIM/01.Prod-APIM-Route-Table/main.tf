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
# Prod APIM 서브넷 생성
resource "azurerm_subnet" "Shared_Prod_APIM_Subnet" {
  name                 = local.variable.prod_apim_subnet
  resource_group_name  = local.variable.shared_rg
  virtual_network_name = local.variable.shared_vnet
  address_prefixes     = local.variable.prod_apim_subnet_prefixs
}
# Prod APIM ALB 서브넷 생성
resource "azurerm_subnet" "Shared_Prod_APIM_ALB_Subnet" {
  name                 = local.variable.prod_apim_alb_subnet
  resource_group_name  = local.variable.shared_rg
  virtual_network_name = local.variable.shared_vnet
  address_prefixes     = local.variable.prod_apim_alb_subnet_prefixs
}
# Shared APIM 라우팅 테이블 생성
resource "azurerm_route_table" "Shared_Apim_Route_Table" {
  name                       = "${local.variable.prod_shared_apim_route_table}"
  location                   = local.variable.location
  resource_group_name        = "${local.variable.shared_rg}"

  dynamic "route" {
    for_each                 = local.variable.prod_apim_routes
    content {
      name                   = "${route.value.name}"
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }

  tags = {
    Creator                  = local.variable.shared_tag_creator
    Environment              = local.variable.shared_tag_environment
    Billing-API              = local.variable.billing_tag
  }
}
# For associate prod apim subnet to route table
resource "azurerm_subnet_route_table_association" "Shared_Prod_APIM_Subnet" {
  subnet_id                  = azurerm_subnet.Shared_Prod_APIM_Subnet.id
  route_table_id             = azurerm_route_table.Shared_Apim_Route_Table.id
}