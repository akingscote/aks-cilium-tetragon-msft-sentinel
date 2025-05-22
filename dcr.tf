resource "azurerm_monitor_data_collection_rule" "toaks" {
  name = "aks-to-msft-sentinel"
  resource_group_name = azurerm_log_analytics_workspace.sentinel.resource_group_name
  location            = azurerm_log_analytics_workspace.sentinel.location
  kind                = "Linux"

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.sentinel.id
      name                  = "ciworkspace"
    }
  }

  data_flow {
    streams      = [
        "Microsoft-ContainerLog",
        "Microsoft-ContainerLogV2",
        "Microsoft-KubeEvents",
        "Microsoft-KubePodInventory"
    ]
    destinations = [ "ciworkspace"]
  }

  data_sources {
    extension {
      name = "ContainerInsightsExtension"
      streams = [
        "Microsoft-ContainerLog",
        "Microsoft-ContainerLogV2",
        "Microsoft-KubeEvents",
        "Microsoft-KubePodInventory"
      ]
      extension_name = "ContainerInsights"
      extension_json = jsonencode({
        dataCollectionSettings = {
            "interval" = "1m"
            "namespaceFilteringMode" = "Off"
            "enableContainerLogV2" = true
        }
      })
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "to-aks" {
    name = "aks-to-msft-sentinel-association"
    target_resource_id = azurerm_kubernetes_cluster.aks.id
    data_collection_rule_id = azurerm_monitor_data_collection_rule.toaks.id
}


# use the configmap for finer-grained control over the logging
# specifically, include tetragon pods in the `kube-system` namespace
data "kubectl_file_documents" "container-cfgmap" {
    content = file("container-insights-configmap.yaml")
}
resource "kubectl_manifest" "container-cfgmap" {
    depends_on = [ azurerm_monitor_data_collection_rule_association.to-aks ]
    yaml_body=data.kubectl_file_documents.container-cfgmap.content      
}