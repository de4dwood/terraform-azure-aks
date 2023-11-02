locals {
  acr_exists = var.acr == {} ? 0 : 1
}

data "azurerm_container_registry" "acr" {
  count = local.acr_exists
  name = var.acr.name
  resource_group_name = var.acr.resource_group_name
}

resource "azurerm_role_assignment" "aks_cluster_to_acr" {
  count                = local.acr_exists
  scope                = data.azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
}