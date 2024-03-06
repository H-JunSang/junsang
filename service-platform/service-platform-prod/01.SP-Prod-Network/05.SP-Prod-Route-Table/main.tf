# SP-Prod 리소스 그룹 정보
data "azurerm_resource_group" "SP_Prod_RG" {
  name     = "${local.variable.prefix}-${local.variable.sp_prod_common_rg}"
}
# Create SP-Prod Common 서브넷 정보
data "azurerm_subnet" "SP_Prod_Common_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.sp_prod_common_subnet}"
  resource_group_name  = "${local.variable.prefix}-${local.variable.sp_prod_common_rg}"
  virtual_network_name = "${local.variable.prefix}-${local.variable.sp_prod_common_vnet}"
}
# Create SP-Prod Route Table
resource "azurerm_route_table" "SP_Prod_Route_Table" {
  name                       = "${local.variable.prefix}-${local.variable.sp_prod_route_table}"
  location                   = local.variable.location
  resource_group_name        = "${local.variable.prefix}-${local.variable.sp_prod_common_rg}"

  dynamic "route" {
    for_each                 = local.variable.sp_prod_routes
    content {
      name                   = "${local.variable.prefix}-${route.value.name}"
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }

  tags = {
    Creator                  = local.variable.sp_prod_common_tag_creator
    Environment              = local.variable.sp_prod_common_tag_environment
  }
}
# For associate sp prod common subnet to route table
resource "azurerm_subnet_route_table_association" "PaaS_SP_Prod_Common_Subnet" {
  subnet_id                  = "${data.azurerm_subnet.SP_Prod_Common_Subnet.id}"
  route_table_id             = azurerm_route_table.SP_Prod_Route_Table.id
}