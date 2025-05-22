/*
hacked together as its a PoC
*/

resource "azurerm_virtual_network" "aks" {
  name                = "${local.config.azure.kubernetes.cluster_prefix}-${local.config.azure.kubernetes.prod.name}-vnet"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = local.config.azure.vnet.address
}

resource "azurerm_subnet" "aks_system" {
  name                 = "${local.config.azure.kubernetes.cluster_prefix}-${local.config.azure.kubernetes.prod.name}-system-subnet"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = local.config.azure.vnet.system_subnet
}

resource "azurerm_subnet" "aks_user" {
  name                 = "${local.config.azure.kubernetes.cluster_prefix}-${local.config.azure.kubernetes.prod.name}-user-subnet"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = local.config.azure.vnet.user_subnet
  private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
}


# hacked together - its as PoC to whatever
resource "azurerm_network_security_group" "aks_system_subnet" {
  name                = "aksSystemSubnetsNSG"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name

  security_rule {
    name                       = "deny-ssh-nodepool"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "aks_user_subnets" {
  name                = "aksUserSubnetsNSG"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name

  security_rule {
    name                       = "deny-ssh-nodepool"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-internal"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "allow-internal-lb"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "allow-external-lb"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "system_nsg" {
  subnet_id                 = azurerm_subnet.aks_system.id
  network_security_group_id = azurerm_network_security_group.aks_system_subnet.id
}

resource "azurerm_subnet_network_security_group_association" "user_nsg" {
  subnet_id                 = azurerm_subnet.aks_user.id
  network_security_group_id = azurerm_network_security_group.aks_user_subnets.id
}