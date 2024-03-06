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
  variable = yamldecode(file("prod_mysql_flexible_srv_variable.yaml"))
}
locals {
  prod_mysql_security_rule = [{
    name                       = "${local.variable.prefix}-Prod-MySql-3306"
    priority                   = "100"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "10.122.0.0/16" # IP 대역 추가 시 변수 이름 복수 처리, 멀
    destination_address_prefix = "*"
  },
  {
    name                       = "${local.variable.prefix}-Prod-MySql-443"
    priority                   = "101"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.122.0.0/16"
    destination_address_prefix = "*"
  }]
}