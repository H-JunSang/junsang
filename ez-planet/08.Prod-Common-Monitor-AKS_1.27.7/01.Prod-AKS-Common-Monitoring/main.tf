# Prod 리소스 그룹 정보
data "azurerm_resource_group" "Prod_RG" {
  name     = "${local.variable.prefix}-${local.variable.prodrg}"
}
# Prod Common 노드 리소스 그룹 정보
data "azurerm_resource_group" "Prod_VMSS_RG" {
  name     = "${local.variable.prefix}-${local.variable.prod_common_node_resorce_group}"
}
# Prod Common 가상 머신 스케일 그룹 리소스 정보
data "azurerm_virtual_machine_scale_set" "Prod_Common_K8S_VMSS_Data" {
  name                = local.variable.prod_common_k8s_vmss_name
  resource_group_name = "${data.azurerm_resource_group.Prod_VMSS_RG.name}"
}
# Prod Common 쿠버네티스 클러스터 정보
data "azurerm_kubernetes_cluster" "Prod_Common_K8s" {
  name                      = "${local.variable.prefix}-${local.variable.prod_common_k8s_name}"
  resource_group_name       = "${data.azurerm_resource_group.Prod_RG.name}"
}
# Prod Common 로그 분석 Work Space 정보
data "azurerm_log_analytics_workspace" "Prod_Common_K8s_log_workspace_name" {
  name                      = "${local.variable.prefix}-${local.variable.prod_common_log_workspace_name}"
  resource_group_name       = "${data.azurerm_resource_group.Prod_RG.name}"
}
# Prod Common 로그 솔루션 정보
data "azurerm_resources" "Prod_Common_K8s_log_solution_name" {
  name                      = local.variable.prod_common_log_solution_name
  resource_group_name       = "${data.azurerm_resource_group.Prod_RG.name}"
}
# Prod Common 가상 머신 스케일 리소스 타입
data "azurerm_resources" "Prod_Common_K8S_VMSS" {
  resource_group_name       = "${data.azurerm_resource_group.Prod_VMSS_RG.name}"
  type                      = local.variable.prod_common_k8s_vmss_resource_type
}
# Prod Common 가상 머신 스케일 리소스 ID
output "Prod_Common_K8S_VMSS_Data_Id" {
  value = data.azurerm_virtual_machine_scale_set.Prod_Common_K8S_VMSS_Data.id
}
# 데이터 수집 생성
resource "azurerm_monitor_data_collection_rule" "Prod_Common_K8S_Data_Rule" {
  name                         = local.variable.prod_common_k8s_data_rule
  resource_group_name          = "${data.azurerm_resource_group.Prod_RG.name}"
  location                     = local.variable.location
  
  data_sources {
    performance_counter {
      name                          = local.variable.prod_common_k8s_data_rule
      streams                       = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["\\VmInsights\\DetailedMetrics"]
    }
  }
  destinations {
    log_analytics {
      workspace_resource_id   = "${data.azurerm_log_analytics_workspace.Prod_Common_K8s_log_workspace_name.id}"
      name                    =  local.variable.prod_common_k8s_destination_log
    }
  }
  data_flow {
    streams                   = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
    destinations              = ["destination-log"]
  }
  depends_on = [ data.azurerm_resources.Prod_Common_K8s_log_solution_name ]
}
resource "azurerm_monitor_data_collection_rule_association" "Prod_Common_k8s_data_collection_associate" {
  name                         = local.variable.prod_common_k8s_data_collection_associate_name
  target_resource_id           = "${data.azurerm_virtual_machine_scale_set.Prod_Common_K8S_VMSS_Data.id}"
  data_collection_rule_id      = azurerm_monitor_data_collection_rule.Prod_Common_K8S_Data_Rule.id
}
resource "azurerm_virtual_machine_scale_set_extension" "Prod_Common_K8s_Monitoring" {
  count                        = length(data.azurerm_resources.Prod_Common_K8S_VMSS.resources)

  name                         = local.variable.prod_common_K8s_monitoring_name
  virtual_machine_scale_set_id = data.azurerm_resources.Prod_Common_K8S_VMSS.resources[count.index].id
  publisher                    = local.variable.prod_common_k8s_mnitoring_publisher
  type                         = local.variable.prod_common_k8s_monitoring_type
  type_handler_version         = local.variable.prod_common_k8s_monitoring_type_version
  auto_upgrade_minor_version   = local.variable.prod_common_k8s_monitoring_minor_ver

  settings = <<SETTINGS
  {
    "workspaceId": "${data.azurerm_log_analytics_workspace.Prod_Common_K8s_log_workspace_name.id}"
  }
SETTINGS
  depends_on = [ data.azurerm_kubernetes_cluster.Prod_Common_K8s ]
}