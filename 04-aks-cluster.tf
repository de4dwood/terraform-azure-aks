data "azurerm_kubernetes_service_versions" "current" {
  location        = azurerm_resource_group.main_rg.location
  version_prefix  = var.aks_version_prefix
  include_preview = false
}

locals {
  aks_network_profile = {
    network_plugin    = lookup(var.aks_network_profile, "network_plugin", "azure")
    network_policy    = lookup(var.aks_network_profile, "network_policy", "calico")
    load_balancer_sku = lookup(var.aks_network_profile, "load_balancer_sku", "standard")
    service_cidr      = lookup(var.aks_network_profile, "service_cidr", "10.85.0.0/16")
    dns_service_ip    = lookup(var.aks_network_profile, "dns_service_ip", "10.85.0.10")
  }
  aks_default_node_pool = {
    vm_size             = lookup(var.aks_default_node_pool, "vm_size", "Standard_D2ds_v4")
    zones               = lookup(var.aks_default_node_pool, "zones", [])
    enable_auto_scaling = lookup(var.aks_default_node_pool, "enable_auto_scaling", false)
    max_count           = lookup(var.aks_default_node_pool, "enable_auto_scaling", false) != true ? null : lookup(var.aks_default_node_pool, "max_count", 1)
    min_count           = lookup(var.aks_default_node_pool, "enable_auto_scaling", false) != true ? null : lookup(var.aks_default_node_pool, "min_count", 1)
    node_count          = lookup(var.aks_default_node_pool, "enable_auto_scaling", false) == true ?  null : lookup(var.aks_default_node_pool, "node_count", 1)
    os_disk_size_gb     = lookup(var.aks_default_node_pool, "os_disk_size_gb", 50)
  }
}
resource "tls_private_key" "aks_ssh" {
  count     = var.ssh_public_key == null ? 1 : 0
  algorithm = "RSA"
}


resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "aks-${local.X}"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
  dns_prefix          = "aks-${local.X}"
  kubernetes_version  = data.azurerm_kubernetes_service_versions.current.latest_version
  node_resource_group = "${azurerm_resource_group.main_rg.name}-aks-nrg"

  default_node_pool {
    name                 = var.product_name
    vm_size              = local.aks_default_node_pool.vm_size
    orchestrator_version = data.azurerm_kubernetes_service_versions.current.latest_version
    zones                = local.aks_default_node_pool.zones
    enable_auto_scaling  = local.aks_default_node_pool.enable_auto_scaling
    max_count            = local.aks_default_node_pool.max_count
    min_count            = local.aks_default_node_pool.min_count
    node_count           = local.aks_default_node_pool.node_count
    os_disk_size_gb      = local.aks_default_node_pool.os_disk_size_gb
    os_disk_type         = "Ephemeral"
    max_pods             = 75
    type                 = "VirtualMachineScaleSets"
    vnet_subnet_id       = azurerm_subnet.snet_aks.id
    node_labels = {
      "nodepool-type" = "main"
      "environment"   = "${var.environment}"
      "nodepoolos"    = "linux"
      "app"           = "${var.product_name}"
    }
    tags = {
      "nodepool-type" = "main"
      "environment"   = "${var.environment}"
      "nodepoolos"    = "linux"
      "app"           = "${var.product_name}"
    }
  }
  identity {
    type = "SystemAssigned"
  }
  http_application_routing_enabled  = false
  role_based_access_control_enabled = true
  linux_profile {
    admin_username = "ubuntu"
    ssh_key {
      key_data = var.ssh_public_key == null ? tls_private_key.aks_ssh[0].public_key_pem : file(var.ssh_public_key)
    }
  }
  network_profile {
    network_plugin    = local.aks_network_profile.network_plugin
    network_policy    = local.aks_network_profile.network_policy
    load_balancer_sku = local.aks_network_profile.load_balancer_sku
    service_cidr      = local.aks_network_profile.service_cidr
    dns_service_ip    = local.aks_network_profile.dns_service_ip
    dynamic "load_balancer_profile" {
      for_each = local.aks_network_profile.load_balancer_sku == "basic" ? [] : [1]
      content {
        outbound_ip_address_ids = [azurerm_public_ip.pip_aks.id]
      }
    }
  }

  tags = {
    Environment = "${var.environment}"
    Provisioned = "Terraform"
  }
}

resource "azurerm_role_assignment" "aks_cluster_to_aks_vnet" {
  scope                = azurerm_virtual_network.vnet_aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_cluster_to_public_ip" {
  scope                = azurerm_public_ip.pip_aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
}