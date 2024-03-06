# Shared 리소스 그룹 정보
data "azurerm_resource_group" "Shared_RG" {
  name     = "${local.variable.prefix}-${local.variable.sharedrg}"
}
# Shared 네트워크  정보
data "azurerm_virtual_network" "Shared_vNet" {
  name                = "${local.variable.prefix}-${local.variable.shared_vnet}"
  resource_group_name = "${data.azurerm_resource_group.Shared_RG.name}"
}
# Shared 쿠버네티스 서브넷 정보
data "azurerm_subnet" "Shared_K8S_Subnet" {
  name                 = "${local.variable.prefix}-${local.variable.shared_k8s_subnet}"
  resource_group_name  = "${data.azurerm_resource_group.Shared_RG.name}"
  virtual_network_name = "${data.azurerm_virtual_network.Shared_vNet.name}"
}
# Shared K8S L7 로드밸런서 정보
data "azurerm_application_gateway" "Shared_L7_Loadbalancer" {
  name                 = "${local.variable.prefix}-${local.variable.shared_k8s_l7_gateway_name}"
  resource_group_name  = "${data.azurerm_resource_group.Shared_RG.name}"
}
# Create Shared K8S 
resource "azurerm_kubernetes_cluster" "Shared_Kubernetes" {
  name                    = "${local.variable.prefix}-${local.variable.shared_k8s_name}"
  location                = local.variable.location
  resource_group_name     = "${data.azurerm_resource_group.Shared_RG.name}"
  kubernetes_version      = local.variable.k8s_version
  dns_prefix              = local.variable.shared_k8s_dns_prefix
  sku_tier                = local.variable.k8s_sku_tier
  private_cluster_enabled = local.variable.private_cluster
  azure_policy_enabled    = local.variable.azure_policy_enabled
  node_resource_group     = "${local.variable.prefix}-${local.variable.shared_node_resorce_group}"

# OMS 에이전트 설정 
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.Shared_K8S_Log_Workspace.id
  }

# L7 로드밸런서 Integration
  ingress_application_gateway {
    gateway_id            = "${data.azurerm_application_gateway.Shared_L7_Loadbalancer.id}"
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
    name                  = local.variable.shared_agent_pool
    node_count            = local.variable.shared_agent_pool_count
    vm_size               = local.variable.shared_agent_pool_vm_size
    vnet_subnet_id        = "${data.azurerm_subnet.Shared_K8S_Subnet.id}"
    enable_auto_scaling   = local.variable.auto_scale_false

    node_labels           = {
      "${local.variable.shared_agent_node_label_prefix}" = "${local.variable.shared_agent_node_label}"
    }
  }

# 네트워크 프로파일 설정
  network_profile {
    network_plugin        = local.variable.network_plugin
    network_policy        = local.variable.network_policy

    dns_service_ip        = local.variable.shared_k8s_dns_service_ip
    service_cidr          = local.variable.shared_k8s_service_cidr
    load_balancer_sku     = local.variable.loadbalancer_sku
  }

  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}
# 추가 쿠버네티스 node pool
resource "azurerm_kubernetes_cluster_node_pool" "Shared_Node_Pool" {
  name                    = local.variable.shared_node_pool
  kubernetes_cluster_id   = "${azurerm_kubernetes_cluster.Shared_Kubernetes.id}"
  vm_size                 = local.variable.shared_node_vm_size
  mode                    = local.variable.shared_node_pool_mode
  min_count               = local.variable.shared_node_min_count
  max_count               = local.variable.shared_node_max_count
  max_pods                = local.variable.shared_node_max_pods_count
  enable_auto_scaling     = local.variable.auto_scale_true

  node_labels             = {
    "${local.variable.shared_node_pool_label_prefix}" = "${local.variable.shared_node_pool_label}"
  }
}
# 노드 풀 모니터링 설정
resource "azurerm_monitor_action_group" "Shared_K8S_Monitoring" {
  name                    = "${local.variable.prefix}-${local.variable.shared_alert_action_group}"
  resource_group_name     = "${data.azurerm_resource_group.Shared_RG.name}"
  short_name              = local.variable.shared_cpu_alert_short_name
  email_receiver {
    name                  = "${local.variable.prefix}-${local.variable.shared_alert_email_admin}"
    email_address         = local.variable.shared_alert_email_address
  }
}
# 노드 풀 CPU 알람
resource "azurerm_monitor_metric_alert" "Shard_K8S_CPU_Alert" {
  name                    = "${local.variable.prefix}-${local.variable.shared_cpu_alert_name}"
  resource_group_name     = "${data.azurerm_resource_group.Shared_RG.name}"
  scopes                  = [ azurerm_kubernetes_cluster.Shared_Kubernetes.id ]
  criteria {
    metric_namespace      = local.variable.shared_cpu_metric_namespace
    metric_name           = local.variable.shared_cpu_metric_name
    aggregation           = local.variable.shared_cpu_aggregate
    operator              = local.variable.shared_cpu_operator
    threshold             = local.variable.shared_cpu_threshold
  }

  action {
    action_group_id       = azurerm_monitor_action_group.Shared_K8S_Monitoring.id
  }
}

# 노드 풀 메모리 알람
resource "azurerm_monitor_metric_alert" "Shared_K8S_Mem_Alert" {
  name                    = "${local.variable.prefix}-${local.variable.shared_mem_alert_name}"
  resource_group_name     = "${data.azurerm_resource_group.Shared_RG.name}"
  scopes                  = [ azurerm_kubernetes_cluster.Shared_Kubernetes.id ]
  criteria {
    metric_namespace      = local.variable.shared_mem_metric_namespace
    metric_name           = local.variable.shared_mem_metric_name
    aggregation           = local.variable.shared_mem_aggregate
    operator              = local.variable.shared_mem_operator
    threshold             = local.variable.shared_mem_threshold
  }

  action {
    action_group_id       = azurerm_monitor_action_group.Shared_K8S_Monitoring.id
  }
}

# 노드 풀 로그 분석
resource "azurerm_log_analytics_workspace" "Shared_K8S_Log_Workspace" {
  name                    = "${local.variable.prefix}-${local.variable.shared_log_workspace_name}"
  resource_group_name     = "${data.azurerm_resource_group.Shared_RG.name}"
  location                = local.variable.location
  sku                     = local.variable.shared_log_workspace_name_sku

  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}

# 노드 풀 로그 솔루션
resource "azurerm_log_analytics_solution" "Shared_K8S_Log_Solution" {
  solution_name           = local.variable.shared_log_solution_name
  location                = local.variable.location
  resource_group_name     = "${data.azurerm_resource_group.Shared_RG.name}"
  workspace_resource_id   = azurerm_log_analytics_workspace.Shared_K8S_Log_Workspace.id
  workspace_name          = azurerm_log_analytics_workspace.Shared_K8S_Log_Workspace.name

  plan {
    publisher             = local.variable.publisher
    product               = local.variable.product
  }

  tags = {
    Creator     = local.variable.shared_tag_creator
    Environment = local.variable.shared_tag_environment
  }
}

# 노드 풀 진단
resource "azurerm_monitor_diagnostic_setting" "Shared_K8S_Diag" {
  name                       = "${local.variable.prefix}-${local.variable.shared_diag_name}"
  target_resource_id         = azurerm_kubernetes_cluster.Shared_Kubernetes.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.Shared_K8S_Log_Workspace.id

  dynamic "enabled_log" {
    for_each = local.variable.shared_k8s_log
    content {
      category = enabled_log.value.name
    }
  }
  dynamic "metric" {
    for_each = local.variable.shared_k8s_metric
    content {
      category = metric.value.name
      enabled  = local.variable.shared_k8s_metric_enabled
    }
  }
}
