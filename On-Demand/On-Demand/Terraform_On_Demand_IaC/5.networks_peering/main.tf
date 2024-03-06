# Shared virtual network 정보
data "azurerm_virtual_network" "Shared_vNet" {
  name                = "${local.variable.prefix}-${local.variable.shared_vnet}"
  resource_group_name = "${local.variable.prefix}-${local.variable.sharedrg}"
}
# Prod virtual network 정보
data "azurerm_virtual_network" "Prod_vNet" {
  name                = "${local.variable.prefix}-${local.variable.prod_vnet}"
  resource_group_name = "${local.variable.prefix}-${local.variable.prodrg}"
}
# Shared virtual network peering To Prod virtual network
resource "azurerm_virtual_network_peering" "Shared_To_Prod" {
  name                         = "${local.variable.prefix}-${local.variable.paas_shared_to_paas_prod}"
  resource_group_name          = "${data.azurerm_virtual_network.Shared_vNet.resource_group_name}"
  virtual_network_name         = "${data.azurerm_virtual_network.Shared_vNet.name}"
  remote_virtual_network_id    = "${data.azurerm_virtual_network.Prod_vNet.id}"
  allow_virtual_network_access = local.variable.allow_network_access
  allow_forwarded_traffic      = local.variable.allow_forward_traffic
  allow_gateway_transit        = local.variable.allow_gateway_transit
  use_remote_gateways          = local.variable.use_remote_gateway
}
# Prod virtual network peering To Shared virtual network
resource "azurerm_virtual_network_peering" "Prod_To_Shared" {
  name                         = "${local.variable.prefix}-${local.variable.paas_prod_to_paas_shared}"
  resource_group_name          = "${data.azurerm_virtual_network.Prod_vNet.resource_group_name}"
  virtual_network_name         = "${data.azurerm_virtual_network.Prod_vNet.name}"
  remote_virtual_network_id    = "${data.azurerm_virtual_network.Shared_vNet.id}"
  allow_virtual_network_access = local.variable.allow_network_access
  allow_forwarded_traffic      = local.variable.allow_forward_traffic
  allow_gateway_transit        = local.variable.allow_gateway_transit
  use_remote_gateways          = local.variable.use_remote_gateway
}