# Create SP_Prod_Common resource group
resource "azurerm_resource_group" "SP_Prod_Common_rg" {
  name          = "${local.variable.prefix}-${local.variable.sp_prod_common_rg}"
  location      = local.variable.location
  tags     = {
    Creator     = local.variable.sp_prod_common_tag_creator
    Environment = local.variable.sp_prod_common_tag_environment
    Billing-API = local.variable.billing_rg_tag
  }
}
# Create SP_Prod_Common Virtual Network 
resource "azurerm_virtual_network" "SP_Prod_Common_VNET" {
  name                = "${local.variable.prefix}-${local.variable.sp_prod_common_vnet}"
  location            = azurerm_resource_group.SP_Prod_Common_rg.location
  resource_group_name = azurerm_resource_group.SP_Prod_Common_rg.name
  address_space       = [local.variable.sp_prod_common_address_space]
  dynamic "subnet" {
    for_each = local.variable.sp_prod_common_subnets
    content {
      name            = "${local.variable.prefix}-${subnet.value.name}"
      address_prefix  = subnet.value.iprange
    }
  }
  tags = {
    Creator     = local.variable.sp_prod_common_tag_creator
    Environment = local.variable.sp_prod_common_tag_environment
    Billing-API = local.variable.billing_tag
  }
}