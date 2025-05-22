output "_connection_string" {
  value       = "az aks get-credentials --name ${azurerm_kubernetes_cluster.aks.name} --resource-group ${azurerm_resource_group.aks.name} --overwrite-existing"
  description = "CLI command for obtaining Kubernetes credentials for the AKS cluster."
}

output "_vnet_id" {
  value       = azurerm_virtual_network.aks.id
  description = "Azure VNet ID for use when performing network peering or VPNs."
}

output "aks_workload_identity_user_client_id" {
  value       = "${azurerm_user_assigned_identity.wi_user.client_id}"
  description = "Client ID of the WI user (required for k8s service account)"
}