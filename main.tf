terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.50.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.0.3"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
module "storage" {
  source = "./storage"
}

module "compute" {
  source = "./compute"

  pvc = module.storage.pvc
}