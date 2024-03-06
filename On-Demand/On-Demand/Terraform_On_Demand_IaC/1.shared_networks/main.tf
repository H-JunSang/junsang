# Create Shared resource group
resource "azurerm_resource_group" "Shared_rg" {
  name          = "${local.variable.prefix}-${local.variable.sharedrg}"
  location      = local.variable.location
  tags     = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}
# Create Shared Virtual Network 
resource "azurerm_virtual_network" "Shared_VNET" {
  name                = "${local.variable.prefix}-${local.variable.shared_vnet}"
  location            = azurerm_resource_group.Shared_rg.location
  resource_group_name = azurerm_resource_group.Shared_rg.name
  address_space       = [local.variable.shared_address_space]
  dynamic "subnet" {
    for_each = local.variable.shared_subnets
    content {
      name            = "${local.variable.prefix}-${subnet.value.name}"
      address_prefix  = subnet.value.iprange
    }
  }
  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}