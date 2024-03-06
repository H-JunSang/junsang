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
  variable = yamldecode(file("mgmt_peering_variable.yaml"))
}
# SP-IT virtual network 정보
data "azurerm_virtual_network" "SP_IT_vNet" {
  name                = "${local.variable.prefix}-${local.variable.sp_it_common_vnet}"
  resource_group_name = "${local.variable.prefix}-${local.variable.sp_it_common_rg}"
}
# SP-IT virtual network peering To Mgmt virtual network
resource "azurerm_virtual_network_peering" "SP_IT_To_MGMT" {
  name                         = "${local.variable.prefix}-${local.variable.paas_sp_it_to_mgmt}"
  resource_group_name          = "${data.azurerm_virtual_network.SP_IT_vNet.resource_group_name}"
  virtual_network_name         = "${data.azurerm_virtual_network.SP_IT_vNet.name}"
  remote_virtual_network_id    = local.variable.mgmt_virtual_network_id
  allow_virtual_network_access = local.variable.sp_it_allow_network_access
  allow_forwarded_traffic      = local.variable.sp_it_allow_forward_traffic
  allow_gateway_transit        = local.variable.sp_it_allow_gateway_transit
  use_remote_gateways          = local.variable.sp_it_use_remote_gateway
}