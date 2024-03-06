# Create prod resource group
resource "azurerm_resource_group" "Prod_rg" {
  name          = "${local.variable.prefix}-${local.variable.prodrg}"
  location      = local.variable.location
  tags     = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_tag_environment
  }
}
# Create prod Virtual Network 
resource "azurerm_virtual_network" "Prod_VNET" {
  name                = "${local.variable.prefix}-${local.variable.prod_vnet}"
  location            = azurerm_resource_group.Prod_rg.location
  resource_group_name = azurerm_resource_group.Prod_rg.name
  address_space       = [local.variable.prod_address_space]
  dynamic "subnet" {
    for_each = local.variable.prod_subnets
    content {
      name            = "${local.variable.prefix}-${subnet.value.name}"
      address_prefix  = subnet.value.iprange
    }
  }
  tags = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_tag_environment
    Billing-API = local.variable.billing_api_tag
  }
}
