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
  variable = yamldecode(file("api_management_variable.yaml"))
}
# Shared 네트워크 정보
data "azurerm_virtual_network" "Shared_vNet" {
  name                = local.variable.shared_vnet
  resource_group_name = local.variable.shared_rg
}
# Shared APIM 서브넷 정보
data "azurerm_subnet" "Shard_Prod_Apim_Subnet" {
  name                 = local.variable.prod_apim_subnet
  resource_group_name  = local.variable.shared_rg
  virtual_network_name = local.variable.shared_vnet
}
# Shared Identity 정보
/*data "azurerm_user_assigned_identity" "Shared_Key_Vault_Identity" {
  name                 = local.variable.shared_user_managed_identity
  resource_group_name  = local.variable.shared_rg
}*/
# API Management PIP
resource "azurerm_public_ip" "Shared_Prod_Apim_PIP" {
  name                    = local.variable.shared_prod_apim_pip
  resource_group_name     = local.variable.shared_rg
  location                = local.variable.location
  allocation_method       = local.variable.allocation_method
  sku                     = local.variable.sku
  sku_tier                = local.variable.sku_tier
  zones                   = local.variable.zones
  idle_timeout_in_minutes = local.variable.idle_timeout_in_minutes
  ip_version              = local.variable.ip_version
  domain_name_label       = local.variable.domain_name_label
}
# API Management 생성
resource "azurerm_api_management" "Shared_Prod_Apim_Name" {
  name                 = local.variable.shared_prod_apim_name
  resource_group_name  = local.variable.shared_rg
  location             = local.variable.location
  publisher_name       = local.variable.publisher_name
  publisher_email      = local.variable.publisher_email
  sku_name             = local.variable.sku_name
  virtual_network_type = local.variable.network_type
  zones                = local.variable.zones
  public_ip_address_id = azurerm_public_ip.Shared_Prod_Apim_PIP.id

  virtual_network_configuration {
    subnet_id          = "${data.azurerm_subnet.Shard_Prod_Apim_Subnet.id}"
  }

# User Managed Idendity 할당
  /*identity {
    type               = local.variable.identity
    identity_ids       = [ data.azurerm_user_assigned_identity.Shared_Key_Vault_Identity.id ]
  }*/
  
# 보안 프로토콜 적용
  security {
    enable_backend_ssl30                                = local.variable.enable_backend_ssl30
    enable_backend_tls10                                = local.variable.enable_backend_tls10
    enable_backend_tls11                                = local.variable.enable_backend_tls11
    enable_frontend_ssl30                               = local.variable.enable_frontend_ssl30
    enable_frontend_tls10                               = local.variable.enable_frontend_tls10
    enable_frontend_tls11                               = local.variable.enable_frontend_tls11
    tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled = local.variable.tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled
    tls_ecdhe_ecdsa_with_aes256_cbc_sha_ciphers_enabled = local.variable.tls_ecdhe_ecdsa_with_aes256_cbc_sha_ciphers_enabled
    tls_ecdhe_rsa_with_aes128_cbc_sha_ciphers_enabled   = local.variable.tls_ecdhe_rsa_with_aes128_cbc_sha_ciphers_enabled
    tls_ecdhe_rsa_with_aes256_cbc_sha_ciphers_enabled   = local.variable.tls_ecdhe_rsa_with_aes256_cbc_sha_ciphers_enabled
    tls_rsa_with_aes128_cbc_sha256_ciphers_enabled      = local.variable.tls_rsa_with_aes128_cbc_sha256_ciphers_enabled
    tls_rsa_with_aes128_cbc_sha_ciphers_enabled         = local.variable.tls_rsa_with_aes128_cbc_sha_ciphers_enabled
    tls_rsa_with_aes128_gcm_sha256_ciphers_enabled      = local.variable.tls_rsa_with_aes128_gcm_sha256_ciphers_enabled
    tls_rsa_with_aes256_gcm_sha384_ciphers_enabled      = local.variable.tls_rsa_with_aes256_gcm_sha384_ciphers_enabled
    tls_rsa_with_aes256_cbc_sha256_ciphers_enabled      = local.variable.tls_rsa_with_aes256_cbc_sha256_ciphers_enabled
    tls_rsa_with_aes256_cbc_sha_ciphers_enabled         = local.variable.tls_rsa_with_aes256_cbc_sha_ciphers_enabled
    triple_des_ciphers_enabled                          = local.variable.triple_des_ciphers_enabled
  }
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
    Billing-API = local.variable.billing_tag
  }
}