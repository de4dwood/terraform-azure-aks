output "rg" {
  value = {
    name = azurerm_resource_group.main_rg.name
    id   = azurerm_resource_group.main_rg.id
  }
}
output "aks" {
  value = {
    public_address  = azurerm_public_ip.pip_aks.id
    id              = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
    kube_config     = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
    public_key_pem  = var.ssh_public_key == null ? tls_private_key.aks_ssh[0].public_key_pem : ""
    private_key_pem = var.ssh_public_key == null ? tls_private_key.aks_ssh[0].public_key_pem : ""
  }
}