data "azurerm_resource_group" "Shared_RG" {
  name     = "${local.variable.prefix}-${local.variable.sharedrg}"
}
resource "azurerm_dns_zone" "datacloudstack" {
  name                = local.variable.public_dns_zone_name
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
  
  soa_record {
    email = local.variable.public_dns_email
  }

  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}