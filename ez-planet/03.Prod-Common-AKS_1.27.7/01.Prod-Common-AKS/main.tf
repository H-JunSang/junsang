# Prod 리소스 그룹 정보
data "azurerm_resource_group" "Prod_RG" {
  name     = "${local.variable.prefix}-${local.variable.prodrg}"
}
# Prod 네트워크  정보
data "azurerm_virtual_network" "Prod_vNet" {
  name                = "${local.variable.prefix}-${local.variable.prod_vnet}"
  resource_group_name = "${data.azurerm_resource_group.Prod_RG.name}"
}
# Prod Common 쿠버네티스 서브넷 정보
data "azurerm_subnet" "Prod_Common_K8S_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.prod_common_subnet}"
  resource_group_name  = "${data.azurerm_resource_group.Prod_RG.name}"
  virtual_network_name = "${data.azurerm_virtual_network.Prod_vNet.name}"
}
# Prod Common K8S L7 로드밸런서 정보
data "azurerm_application_gateway" "Prod_Common_L7_Loadbalancer" {
  name                 = "${local.variable.prefix}-${local.variable.prod_common_k8s_l7_gateway_name}"
  resource_group_name  = "${data.azurerm_resource_group.Prod_RG.name}"
}
# Create Private DNS Zone
resource "azurerm_private_dns_zone" "Prod_Common_Private_Dns_Zone" {
  name                = local.variable.prod_common_private_dns_zone
  resource_group_name = "${data.azurerm_resource_group.Prod_RG.name}"

  lifecycle {
    ignore_changes = all
  }
}
# Create Prod Virtual Link
resource "azurerm_private_dns_zone_virtual_network_link" "Prod_Common_Virtual_Link" {
  name                  = local.variable.prod_common_virtual_link
  resource_group_name   = "${data.azurerm_resource_group.Prod_RG.name}"
  private_dns_zone_name = azurerm_private_dns_zone.Prod_Common_Private_Dns_Zone.name
  virtual_network_id    = "${data.azurerm_virtual_network.Prod_vNet.id}"

  lifecycle {
    ignore_changes = all
  }
}
# Create Shared Virtual Link
resource "azurerm_private_dns_zone_virtual_network_link" "Shared_Virtual_Link" {
  name                  = local.variable.shared_virtual_link
  resource_group_name   = "${data.azurerm_resource_group.Prod_RG.name}"
  private_dns_zone_name = azurerm_private_dns_zone.Prod_Common_Private_Dns_Zone.name
  virtual_network_id    = local.variable.shared_virtual_network_id

  lifecycle {
    ignore_changes = all
  }
}
# Create SP-Prod Virtual Link
resource "azurerm_private_dns_zone_virtual_network_link" "SP-Prod_Virtual_Link" {
  name                  = local.variable.sp_prod_virtual_link
  resource_group_name   = "${data.azurerm_resource_group.Prod_RG.name}"
  private_dns_zone_name = azurerm_private_dns_zone.Prod_Common_Private_Dns_Zone.name
  virtual_network_id    = local.variable.sp_prod_virtual_network_id

  lifecycle {
    ignore_changes = all
  }
}
# Create Mgmt Virtual Link
resource "azurerm_private_dns_zone_virtual_network_link" "Mgmt_Virtual_Link" {
  name                  = local.variable.laonpeople_mgmt_virutal_link
  resource_group_name   = "${data.azurerm_resource_group.Prod_RG.name}"
  private_dns_zone_name = azurerm_private_dns_zone.Prod_Common_Private_Dns_Zone.name
  virtual_network_id    = local.variable.laonpeople_mgmt_virtual_network_id

  lifecycle {
    ignore_changes = all
  }
}
# Create Prod Common K8S 
resource "azurerm_kubernetes_cluster" "Prod_Common_Kubernetes" {
  name                       = "${local.variable.prefix}-${local.variable.prod_common_k8s_name}"
  location                   = local.variable.location
  resource_group_name        = "${data.azurerm_resource_group.Prod_RG.name}"
  kubernetes_version         = local.variable.k8s_version
  dns_prefix_private_cluster = local.variable.prod_common_k8s_dns_prefix
  sku_tier                   = local.variable.k8s_sku_tier
  private_cluster_enabled    = local.variable.private_cluster
  private_dns_zone_id        = azurerm_private_dns_zone.Prod_Common_Private_Dns_Zone.id
  azure_policy_enabled       = local.variable.azure_policy_enabled
  node_resource_group        = "${local.variable.prefix}-${local.variable.prod_common_node_resorce_group}"

# OMS 에이전트 설정 
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.Prod_Common_K8S_Log_Workspace.id
  }

# L7 로드밸런서 Integration
  ingress_application_gateway {
    gateway_id            = "${data.azurerm_application_gateway.Prod_Common_L7_Loadbalancer.id}"
  }

# If CSI Driver is enabled, set disk and file dirver enabled true
  storage_profile {
    disk_driver_enabled   = local.variable.disk_driver_enabled
    file_driver_enabled   = local.variable.file_driver_enabled
  }

# If secret store CSI driver on the AKS cluster be enabled, set it true
  key_vault_secrets_provider {
    secret_rotation_enabled    = local.variable.secret_rotation_enabled
    secret_rotation_interval   = local.variable.secret_rotation_interval
  }

# Kubernetes Service Principal
  service_principal {
    client_id                  = local.variable.service_appid
    client_secret              = local.variable.service_secret
  }

# 쿠버네티스 기본 노드 풀 생성
  default_node_pool {
    name                  = local.variable.prod_common_agent_pool
    vm_size               = local.variable.prod_common_agent_pool_vm_size
    vnet_subnet_id        = "${data.azurerm_subnet.Prod_Common_K8S_Subnet.id}"
    node_count            = local.variable.prod_common_agent_pool_count
    enable_auto_scaling   = local.variable.auto_scale_false

    node_labels           = {
      "${local.variable.prod_common_agent_node_label_prefix}" = "${local.variable.prod_common_agent_node_label}"
    }
  }

# 네트워크 프로파일 설정
  network_profile {
    network_plugin        = local.variable.network_plugin
    network_policy        = local.variable.network_policy

    dns_service_ip        = local.variable.prod_common_k8s_dns_service_ip
    service_cidr          = local.variable.prod_common_k8s_service_cidr
    load_balancer_sku     = local.variable.loadbalancer_sku
  }

  tags = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_common_tag_environment
    Billing-API = local.variable.billing_api_tag
    test-tag    = local.variable.test_tag
  }
}
# Prod Common Shared 쿠버네티스 node pool
resource "azurerm_kubernetes_cluster_node_pool" "Prod_Common_Shared_Node_Pool" {
  name                    = local.variable.prod_common_shared_node_pool
  kubernetes_cluster_id   = "${azurerm_kubernetes_cluster.Prod_Common_Kubernetes.id}"
  vm_size                 = local.variable.prod_common_shared_node_vm_size
  mode                    = local.variable.prod_node_pool_mode
  min_count               = local.variable.prod_common_shared_node_min_count
  max_count               = local.variable.prod_common_shared_node_max_count
  max_pods                = local.variable.prod_node_max_pods_count
  enable_auto_scaling     = local.variable.auto_scale_true

  node_labels             = {
    "${local.variable.prod_common_shared_node_pool_label_prefix_1}" = "${local.variable.prod_common_shared_node_pool_label_1}"
    "${local.variable.prod_common_shared_node_pool_label_prefix_2}" = "${local.variable.prod_common_shared_node_pool_label_2}"
    "${local.variable.prod_common_shared_node_pool_label_prefix_3}" = "${local.variable.prod_common_shared_node_pool_label_3}"
    "${local.variable.prod_common_shared_node_pool_label_prefix_4}" = "${local.variable.prod_common_shared_node_pool_label_4}"
    "${local.variable.prod_common_shared_node_pool_label_prefix_5}" = "${local.variable.prod_common_shared_node_pool_label_5}"
  }

  lifecycle {
    ignore_changes = all
  }
}
# Prod Common Service 쿠버네티스 node pool
resource "azurerm_kubernetes_cluster_node_pool" "Prod_Common_Service_Node_Pool" {
  name                    = local.variable.prod_common_service_node_pool
  kubernetes_cluster_id   = "${azurerm_kubernetes_cluster.Prod_Common_Kubernetes.id}"
  vm_size                 = local.variable.prod_common_service_node_vm_size
  mode                    = local.variable.prod_node_pool_mode
  min_count               = local.variable.prod_common_service_node_min_count
  max_count               = local.variable.prod_common_service_node_max_count
  max_pods                = local.variable.prod_node_max_pods_count
  enable_auto_scaling     = local.variable.auto_scale_true

  node_labels             = {
    "${local.variable.prod_common_service_node_pool_label_prefix_1}" = "${local.variable.prod_common_service_node_pool_label_1}"
    "${local.variable.prod_common_service_node_pool_label_prefix_2}" = "${local.variable.prod_common_service_node_pool_label_2}"
    "${local.variable.prod_common_service_node_pool_label_prefix_3}" = "${local.variable.prod_common_service_node_pool_label_3}"
    "${local.variable.prod_common_service_node_pool_label_prefix_4}" = "${local.variable.prod_common_service_node_pool_label_4}"
    "${local.variable.prod_common_service_node_pool_label_prefix_5}" = "${local.variable.prod_common_service_node_pool_label_5}"
  }

  lifecycle {
    ignore_changes = all
  }
}
# Prod Common MSB 쿠버네티스 node pool
resource "azurerm_kubernetes_cluster_node_pool" "Prod_Common_Msb_Node_Pool" {
  name                    = local.variable.prod_common_msb_node_pool
  kubernetes_cluster_id   = "${azurerm_kubernetes_cluster.Prod_Common_Kubernetes.id}"
  vm_size                 = local.variable.prod_common_msb_node_vm_size
  mode                    = local.variable.prod_node_pool_mode
  min_count               = local.variable.prod_common_msb_node_min_count
  max_count               = local.variable.prod_common_msb_node_max_count
  max_pods                = local.variable.prod_common_msb_max_pods_count
  enable_auto_scaling     = local.variable.auto_scale_true
  node_taints             = local.variable.prod_common_msb_node_pool_taints

  node_labels             = {
    "${local.variable.prod_common_msb_node_pool_label_prefix_1}" = "${local.variable.prod_common_msb_node_pool_label_1}"
    "${local.variable.prod_common_msb_node_pool_label_prefix_2}" = "${local.variable.prod_common_msb_node_pool_label_2}"
    "${local.variable.prod_common_msb_node_pool_label_prefix_3}" = "${local.variable.prod_common_msb_node_pool_label_3}"
    "${local.variable.prod_common_msb_node_pool_label_prefix_4}" = "${local.variable.prod_common_msb_node_pool_label_4}"
    "${local.variable.prod_common_msb_node_pool_label_prefix_5}" = "${local.variable.prod_common_msb_node_pool_label_5}"
  }

  lifecycle {
    ignore_changes = all
  }
}
# Prod Common DB 쿠버네티스 node pool
resource "azurerm_kubernetes_cluster_node_pool" "Prod_Common_DB_Node_Pool" {
  name                    = local.variable.prod_common_db_node_pool
  kubernetes_cluster_id   = "${azurerm_kubernetes_cluster.Prod_Common_Kubernetes.id}"
  vm_size                 = local.variable.prod_common_db_node_vm_size
  mode                    = local.variable.prod_node_pool_mode
  min_count               = local.variable.prod_common_db_node_min_count
  max_count               = local.variable.prod_common_db_node_max_count
  max_pods                = local.variable.prod_common_db_max_pods_count
  enable_auto_scaling     = local.variable.auto_scale_true
  node_taints             = local.variable.prod_common_db_node_pool_taints

  node_labels             = {
    "${local.variable.prod_common_db_node_pool_label_prefix_1}" = "${local.variable.prod_common_db_node_pool_label_1}"
    "${local.variable.prod_common_db_node_pool_label_prefix_2}" = "${local.variable.prod_common_db_node_pool_label_2}"
    "${local.variable.prod_common_db_node_pool_label_prefix_3}" = "${local.variable.prod_common_db_node_pool_label_3}"
    "${local.variable.prod_common_db_node_pool_label_prefix_4}" = "${local.variable.prod_common_db_node_pool_label_4}"
    "${local.variable.prod_common_db_node_pool_label_prefix_5}" = "${local.variable.prod_common_db_node_pool_label_5}"
  }

  lifecycle {
    ignore_changes = all
  }
}
# 노드 풀 모니터링 설정
resource "azurerm_monitor_action_group" "Prod_Common_K8S_Monitoring" {
  name                    = "${local.variable.prefix}-${local.variable.prod_common_alert_action_group}"
  resource_group_name     = "${data.azurerm_resource_group.Prod_RG.name}"
  short_name              = local.variable.prod_common_cpu_alert_short_name
  email_receiver {
    name                  = "${local.variable.prefix}-${local.variable.prod_common_alert_email_admin}"
    email_address         = local.variable.prod_common_alert_email_address
  }

  lifecycle {
    ignore_changes = all
  }
}
# 노드 풀 CPU 알람
resource "azurerm_monitor_metric_alert" "Prod_Common_K8S_CPU_Alert" {
  name                    = "${local.variable.prefix}-${local.variable.prod_common_cpu_alert_name}"
  resource_group_name     = "${data.azurerm_resource_group.Prod_RG.name}"
  scopes                  = [ azurerm_kubernetes_cluster.Prod_Common_Kubernetes.id ]
  criteria {
    metric_namespace      = local.variable.prod_common_cpu_metric_namespace
    metric_name           = local.variable.prod_common_cpu_metric_name
    aggregation           = local.variable.prod_common_cpu_aggregate
    operator              = local.variable.prod_common_cpu_operator
    threshold             = local.variable.prod_common_cpu_threshold
  }

  action {
    action_group_id       = azurerm_monitor_action_group.Prod_Common_K8S_Monitoring.id
  }

  lifecycle {
    ignore_changes = all
  }
}

# 노드 풀 메모리 알람
resource "azurerm_monitor_metric_alert" "Prod_Common_K8S_Mem_Alert" {
  name                    = "${local.variable.prefix}-${local.variable.prod_common_mem_alert_name}"
  resource_group_name     = "${data.azurerm_resource_group.Prod_RG.name}"
  scopes                  = [ azurerm_kubernetes_cluster.Prod_Common_Kubernetes.id ]
  criteria {
    metric_namespace      = local.variable.prod_common_mem_metric_namespace
    metric_name           = local.variable.prod_common_mem_metric_name
    aggregation           = local.variable.prod_common_mem_aggregate
    operator              = local.variable.prod_common_mem_operator
    threshold             = local.variable.prod_common_mem_threshold
  }

  action {
    action_group_id       = azurerm_monitor_action_group.Prod_Common_K8S_Monitoring.id
  }

  lifecycle {
    ignore_changes = all
  }
}

# 노드 풀 로그 분석
resource "azurerm_log_analytics_workspace" "Prod_Common_K8S_Log_Workspace" {
  name                    = "${local.variable.prefix}-${local.variable.prod_common_log_workspace_name}"
  resource_group_name     = "${data.azurerm_resource_group.Prod_RG.name}"
  location                = local.variable.location
  sku                     = local.variable.prod_common_log_workspace_name_sku

  tags = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_common_tag_environment
  }

  lifecycle {
    ignore_changes = all
  }
}

# 노드 풀 로그 솔루션
resource "azurerm_log_analytics_solution" "Prod_Common_K8S_Log_Solution" {
  solution_name           = local.variable.prod_common_log_solution_name
  location                = local.variable.location
  resource_group_name     = "${data.azurerm_resource_group.Prod_RG.name}"
  workspace_resource_id   = azurerm_log_analytics_workspace.Prod_Common_K8S_Log_Workspace.id
  workspace_name          = azurerm_log_analytics_workspace.Prod_Common_K8S_Log_Workspace.name

  plan {
    publisher             = local.variable.publisher
    product               = local.variable.product
  }

  tags = {
    Creator     = local.variable.prod_tag_creator
    Environment = local.variable.prod_common_tag_environment
  }

  lifecycle {
    ignore_changes = all
  }
}

# 노드 풀 진단
resource "azurerm_monitor_diagnostic_setting" "Prod_Common_K8S_Diag" {
  name                       = "${local.variable.prefix}-${local.variable.prod_common_diag_name}"
  target_resource_id         = azurerm_kubernetes_cluster.Prod_Common_Kubernetes.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.Prod_Common_K8S_Log_Workspace.id

  dynamic "enabled_log" {
    for_each = local.variable.prod_common_k8s_log
    content {
      category = enabled_log.value.name
    }
  }
  dynamic "metric" {
    for_each = local.variable.prod_common_k8s_metric
    content {
      category = metric.value.name
      enabled  = local.variable.prod_common_k8s_metric_enabled
    }
  }

  lifecycle {
    ignore_changes = all
  }
}