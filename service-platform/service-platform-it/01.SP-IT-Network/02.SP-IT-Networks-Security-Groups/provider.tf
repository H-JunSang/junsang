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
  variable = yamldecode(file("SP-IT-Networks-Security-Groups-variable.yaml"))
}
locals {
  it_common_storage_security_rule = [{
    name                       = "${local.variable.prefix}-SP-IT-Common-Storage-Inbound-Allow-100"
    priority                   = "100"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }]
}
locals {
  it_common_security_rule = [{
    name                       = "${local.variable.prefix}-SP-IT-Common-Inbound-Allow-100"
    priority                   = "100"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }]
}