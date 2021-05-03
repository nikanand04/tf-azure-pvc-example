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

data "terraform_remote_state" "aks" {
  backend = "remote"
  config  = {
    organization = "nikita_hashi"
    workspaces   = {
      name       = "terraform-provision-aks-cluster"
    }
  }
}

resource "azurerm_managed_disk" "example" {
  name                 = "example"
  location             = data.terraform_remote_state.aks.outputs.resource_group_name.location
  resource_group_name  = data.terraform_remote_state.aks.outputs.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"
  tags = {
    environment = data.terraform_remote_state.aks.outputs.resource_group_name
  }
}

resource "kubernetes_persistent_volume" "my_storage_class" {
  metadata {
    name = "my-storage-class"
  }
  spec {
    capacity = {
      storage = "20Gi"
    }
    storage_class_name = "default"
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      azure_disk {
        caching_mode  = "None"
        data_disk_uri = azurerm_managed_disk.example.id
        disk_name     = "example"
        kind          = "Managed"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "my_pod_storage" {
  metadata {
    name = "my-pod-storage"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
    storage_class_name = "default"
    volume_name = kubernetes_persistent_volume.my_storage_class.metadata.0.name
  }
}

output "pvc" {
  value = kubernetes_persistent_volume_claim.my_pod_storage.metadata[0].name
}
