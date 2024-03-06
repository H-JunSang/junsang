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
   container_name       = "laon-ez-planet-prod-tfstate"
   key                  = "laon_ez_planet_prod_common_external_dns_pod.tfstate"
  }
}
provider "kubernetes" {
  config_path = "/Users/kennethlee/.kube/config"
}
resource "kubernetes_manifest" "ServiceAccount" {
  manifest = yamldecode(file("ServiceAccount.yaml"))
}
resource "kubernetes_manifest" "ClusterRole" {
  manifest = yamldecode(file("ClusterRole.yaml"))
}
resource "kubernetes_manifest" "ClusterRoleBinding" {
  manifest = yamldecode(file("ClusterRoleBinding.yaml"))
}
resource "kubernetes_manifest" "DaemonSet" {
  manifest = yamldecode(file("DaemonSet.yaml"))
}