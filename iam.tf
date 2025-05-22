# Cluster (control plane) identity
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${local.config.azure.kubernetes.cluster_prefix}-${local.config.azure.kubernetes.prod.name}-cluster"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
}

resource "azurerm_role_assignment" "aks" {
  scope                = azurerm_resource_group.aks.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}


# UAID kubelet identity
resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "${local.config.azure.kubernetes.cluster_prefix}-${local.config.azure.kubernetes.prod.name}-kubelet"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
}

resource "azurerm_role_assignment" "kubelet" {
  scope                = azurerm_resource_group.aks.id
  role_definition_name = "Managed Identity Operator" # Read and Assign User Assigned Identity
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
}


# workload identity user - not really used int he demo
resource "azurerm_user_assigned_identity" "wi_user" {
  name                = "${local.config.azure.kubernetes.cluster_prefix}-${local.config.azure.kubernetes.prod.name}-wi-user"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
}