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
  variable = yamldecode(file("sp_prod_mysql_flexible_srv_variable.yaml"))
}
locals {
  sp_prod_mysql_security_rule = [{
    name                       = "${local.variable.prefix}-SP-Prod-MySql-3306"
    priority                   = "100"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefixes    = ["10.124.0.0/16", "10.10.100.0/23", "172.28.0.0/16", "10.100.90.0/23"]
    destination_address_prefix = "*"
  },
  {
    name                       = "${local.variable.prefix}-SP-Prod-MySql-443"
    priority                   = "101"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = ["10.124.0.0/16", "10.10.100.0/23", "172.28.0.0/16", "10.100.90.0/23"]
    destination_address_prefix = "*"
  }]
  /*{
    name                       = "${local.variable.prefix}-Deny-Any"
    priority                   = "102"
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = ["*"]
    destination_address_prefix = "*"
 }]*/
}