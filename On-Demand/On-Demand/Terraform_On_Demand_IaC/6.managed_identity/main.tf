# 리소스 그룹 이름 정보 
data "azurerm_resource_group" "Shared_RG" {
  name     = "${local.variable.prefix}-${local.variable.sharedrg}"
}
# For User Managed Identity To Connect Key Vault
resource "azurerm_user_assigned_identity" "Shared_Key_Vault_MID" {
  location            = local.variable.location
  name                = "${local.variable.prefix}-${local.variable.shared_user_managed_identity}"
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
  tags = {
    Creator = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}