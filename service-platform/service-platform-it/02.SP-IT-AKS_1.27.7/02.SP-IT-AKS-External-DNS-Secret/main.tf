# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.85.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "EZ-Planet-Terraform-IaC-States"
    storage_account_name = "laontfstate01"
    container_name       = "laon-service-platform-it-tfstate"
    key                  = "service_platform_it_external_dns_secret.tfstate"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
resource "null_resource" "kubernetes_namespace"{
  provisioner "local-exec" {
    command = "kubectl create secret generic azure-config-file -n external-dns --from-file azure.json"
  }
}