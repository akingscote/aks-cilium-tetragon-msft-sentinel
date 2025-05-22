/*
https://isovalent.com/partners/azure/
https://isovalent.com/blog/post/microsoft-and-isovalent-bring-ebpf-based-networking-to-azure/

https://github.com/Neutrollized/free-tier-aks/blob/main/main.tf

We cannot use "Azure CNI Powered by Cilium", as its features are too limited.
The AKS cluster must be created with --network-plugin none
*/

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "aks" {
  name     = "${local.config.azure.kubernetes.cluster_prefix}-${local.config.azure.kubernetes.prod.name}-rg"
  location = local.config.azure.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.config.azure.kubernetes.cluster_prefix}-${local.config.azure.kubernetes.prod.name}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku_tier            = "Free" # alternative is Standard
  dns_prefix          = "${local.config.azure.kubernetes.cluster_prefix}-${local.config.azure.kubernetes.prod.name}"

  kubernetes_version  = local.config.azure.kubernetes.version
  run_command_enabled = false # Toggles whether to allow 'az aks command invoke' to interact directly with cluster

  azure_policy_enabled      = false
  workload_identity_enabled = false
  oidc_issuer_enabled       = false

  api_server_access_profile {
    authorized_ip_ranges = ["0.0.0.0/0"]
  }

  # object ID is actually principal ID :/
  kubelet_identity {
    client_id = azurerm_user_assigned_identity.kubelet.client_id
    object_id = azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
  }

  oms_agent {
    msi_auth_for_monitoring_enabled = true
    log_analytics_workspace_id = azurerm_log_analytics_workspace.sentinel.id
  }

  network_profile {
    network_plugin      =  "none" # must be none
    pod_cidrs      = ["10.100.0.0/18"]
    service_cidrs  =  ["10.101.0.0/20"]
    dns_service_ip = "10.101.0.10"
  }

  storage_profile {
    blob_driver_enabled         = false
    disk_driver_enabled         = true
    file_driver_enabled         = false
    snapshot_controller_enabled = true
  }

  # system node pool to host only critical system pods (i.e. CoreDNS)
  # user node pools should be created separately for workloads
  default_node_pool {
    name       = "system"
    node_count = 2
    /*
    With just one node, cilium will show one of the operators in a pending state
    https://github.com/rancher/rke2/issues/933
    */
    vm_size    = local.config.azure.kubernetes.default_node_size
    os_sku     = "Ubuntu"

    node_public_ip_enabled       = false
    fips_enabled                 = false
    vnet_subnet_id               = azurerm_subnet.aks_system.id
    only_critical_addons_enabled = true
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  lifecycle {
    ignore_changes = [
      network_profile,
      default_node_pool[0].upgrade_settings,
    ]
  }
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [ azurerm_kubernetes_cluster.aks ]
  create_duration = "30s"
}

/*
Although we've set the network plugin to none (bring your own CNI), kube-proxy isnt disabled yet
We really want to replace kube-proxy to get a lot of the cilium benefits
https://cilium.io/use-cases/kube-proxy/

By default, AKS will deploy the kube-proxyDaemonSet
https://github.com/Azure/AKS/issues/4563

You can get around it by setting the `kube-proxy-config` to false
https://medium.com/@amitmavgupta/installing-cilium-in-azure-kubernetes-service-byocni-with-no-kube-proxy-825b9007b24b

But first, you need to register the KubeProxyConfigurationPreview feature and provider
az feature register --namespace "Microsoft.ContainerService" --name "KubeProxyConfigurationPreview"
az feature show --namespace "Microsoft.ContainerService" --name "KubeProxyConfigurationPreview"
az provider register --namespace Microsoft.ContainerService

Unfortunately, the AKS terraform provider dosent support directly overwriting kube-proxy-config
https://github.com/hashicorp/terraform-provider-azurerm/issues/19300

So we have to do this workaround
https://github.com/hashicorp/terraform-provider-azurerm/issues/19300#issuecomment-2076240339

Isovalent does this exact step in their module
https://github.com/isovalent/terraform-azure-aks/blob/main/main.tf#L75
*/

resource "azapi_update_resource" "kube_proxy_disabled" {
  depends_on = [ time_sleep.wait_30_seconds ] # we need the AKS cluster to settle a bit first
  resource_id = azurerm_kubernetes_cluster.aks.id
  type        = "Microsoft.ContainerService/managedClusters@2024-02-02-preview"
  body = {
    properties = {
      networkProfile = {
        kubeProxyConfig = {
          enabled = false
        }
      }
    }
  }
  lifecycle {
    ignore_changes = all
  }
}


resource "azurerm_kubernetes_cluster_node_pool" "user" {
  depends_on = [ azapi_update_resource.kube_proxy_disabled ] # cannot provison nodepool whilst the feature enable is going on "Operation is not allowed because there's an in progress create node pool operation"
  name                   = "workloads"
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.aks.id
  vm_size                = local.config.azure.kubernetes.default_node_size
  vnet_subnet_id         = azurerm_subnet.aks_user.id
  node_public_ip_enabled = false
  node_count = 2 # at least one workload node

  auto_scaling_enabled = false

  lifecycle {
    ignore_changes = [
      kubernetes_cluster_id,
    ]
  }
}