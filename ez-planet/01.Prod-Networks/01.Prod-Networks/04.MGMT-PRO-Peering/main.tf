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
# Laopeople Mgmt Network information
data "azurerm_virtual_network" "Laonpeople-Mgmt-vNET" {
  name                = local.variable.mgmt_virtual_network_name
  resource_group_name = local.variable.mgmt_resource_group_name
}
# Mgmt virtual network peering To Prod virtual network
resource "azurerm_virtual_network_peering" "MGMT_To_Prod" {
  name                         = local.variable.paas_mgmt_to_prod
  resource_group_name          = "${data.azurerm_virtual_network.Laonpeople-Mgmt-vNET.resource_group_name}"
  virtual_network_name         = "${data.azurerm_virtual_network.Laonpeople-Mgmt-vNET.name}"
  remote_virtual_network_id    = local.variable.prod_virtual_network_id
  allow_virtual_network_access = local.variable.mgmt_allow_network_access
  allow_forwarded_traffic      = local.variable.mgmt_allow_forward_traffic
  allow_gateway_transit        = local.variable.mgmt_allow_gateway_transit
  use_remote_gateways          = local.variable.mgmt_use_remote_gateway
}