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
  variable = yamldecode(file("api_custom_domain_variable.yaml"))
}
 # Shared 리소스 그룹 정보
data "azurerm_resource_group" "Shared_RG" {
  name     = local.variable.shared_rg
}
# Shared 키볼트 정보
data "azurerm_key_vault" "Shared_Key_Vault" {
  name                 = local.variable.keyvault_name
  resource_group_name  = "${data.azurerm_resource_group.Shared_RG.name}"
}
# Shared Identity 정보
/*data "azurerm_user_assigned_identity" "Shared_Key_Vault_Identity" {
  name                 = local.variable.shared_user_managed_identity
  resource_group_name  = "${data.azurerm_resource_group.Shared_RG.name}"
}*/
# Shared 키볼트 인증서 정보
data "azurerm_key_vault_certificate" "Shared_Key_Vault_Certificate" {
  name                 = local.variable.key_vault_cert_name
  key_vault_id         = "${data.azurerm_key_vault.Shared_Key_Vault.id}"
}
# Shared API Management 정보
data "azurerm_api_management" "Shared_Prod_Apim_Mgmt" {
  name                 = local.variable.shared_prod_apim_name
  resource_group_name  = "${data.azurerm_resource_group.Shared_RG.name}"
}
# Shared API Management Custom 도메인 및 게이트웨이 생성
resource "azurerm_api_management_custom_domain" "Shared_Prod_Apim_Custome_Domain" {
  api_management_id                 = "${data.azurerm_api_management.Shared_Prod_Apim_Mgmt.id}"
  gateway {
    host_name                       = local.variable.hostname
    key_vault_id                    = "${data.azurerm_key_vault_certificate.Shared_Key_Vault_Certificate.secret_id}"
    //ssl_keyvault_identity_client_id = "${data.azurerm_user_assigned_identity.Shared_Key_Vault_Identity.client_id}"
    default_ssl_binding             = local.variable.default_ssl_binding
    negotiate_client_certificate    = local.variable.negotiate_client_certificate
  }
}