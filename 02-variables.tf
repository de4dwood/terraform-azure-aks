variable "location" {
  type        = string
  description = "Azure Region where all these resources will be provisioned"
  default     = "francecentral"
}

variable "product_name" {
  type        = string
  description = "This variable defines the product name that we deploy here"
  default     = "example"
}

variable "environment" {
  type        = string
  description = "This variable defines the Environment"
  default     = "test"
}

# SSH Public Key for Linux VMs
variable "ssh_public_key" {
  default     = null
  description = "This variable defines the SSH Public Key for Linux"
}

variable "postfix" {
  default = "-01"
}

variable "aks_version_prefix" {
  default = "1.26"
}

variable "acr" {
  type    = any
  default = {}
}

variable "aks_default_node_pool" {
  type    = any
  default = {}
}


variable "aks_network_profile" {
  type    = any
  default = {}
}

variable "vnet" {
  type    = any
  default = {}
}
