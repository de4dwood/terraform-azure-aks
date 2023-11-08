locals {
  location_abbreviation = module.location_code.id
  X                     = "${var.product_name}-${var.environment}-${local.location_abbreviation}${var.postfix}"
  vnet = {
    address_space          = lookup(var.vnet, "address_space", ["10.69.0.0/16"])
    snet_address_prefixes  = lookup(var.vnet, "snet_address_prefixes", ["10.69.0.0/24"])
    snet_service_endpoints = lookup(var.vnet, "snet_service_endpoints", [])
  }
}

module "location_code" {
  source   = "de4dwood/location_codes/azure"
  version  = "1.0.0"
  location = var.location
}


resource "azurerm_resource_group" "main_rg" {
  name     = "rg-${local.X}"
  location = var.location
  tags = {
    Environment = "${var.environment}"
    Provisioned = "Terraform"
  }
}

resource "azurerm_virtual_network" "vnet_aks" {
  name                = "vnet-${local.X}"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
  address_space       = local.vnet.address_space

  tags = {
    Environment = "${var.environment}"
    Provisioned = "Terraform"
  }
}

resource "azurerm_subnet" "snet_aks" {
  name                 = "snet-${local.X}"
  virtual_network_name = azurerm_virtual_network.vnet_aks.name
  resource_group_name  = azurerm_resource_group.main_rg.name
  address_prefixes     = local.vnet.snet_address_prefixes
  service_endpoints    = local.vnet.snet_service_endpoints
}

resource "azurerm_public_ip" "pip_aks" {
  name                = "pip-aks-${local.X}"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
  sku                 = local.aks_network_profile.load_balancer_sku == "basic" ? "Basic" : "Standard"
  allocation_method   = "Static"

  tags = {
    Environment = "${var.environment}"
    Provisioned = "Terraform"
  }
}
