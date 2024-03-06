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
  variable = yamldecode(file("shared_network_nsg_variable.yaml"))
}
locals {
  shared_k8s_security_rule = [{
    name                       = "${local.variable.prefix}-Shared-K8S-Inbound-Allow-100" # Prefix From variable.yaml 
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
  shared_storage_security_rule = [{
    name                       = "${local.variable.prefix}-Shared-Storage-Inbound-Allow-100" # Prefix From variable.yaml
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
  shared_ingress_security_rule = [{
    name                       = "${local.variable.prefix}-Shared-Ingress-Inbound-Allow-100" # Prefix From variable.yaml
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
  shared_apim_security_rule = [{
    name                       = "${local.variable.prefix}-Shared-Apim-Inbound-Allow-100" # Prefix From variable.yaml
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
  shared_apim_alb_security_rule = [{
    name                       = "${local.variable.prefix}-Shared-Apim-Alb-Inbound-Allow-100" # Prefix From variable.yaml
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
  prod_apim_security_rule = [{
    name                       = "${local.variable.prefix}-Shared-Apim-Inbound-Allow-100" # Prefix From variable.yaml
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
  prod_apim_alb_security_rule = [{
    name                       = "${local.variable.prefix}-Shared-Apim-Alb-Inbound-Allow-100" # Prefix From variable.yaml
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