provider "azurerm" {
  features {}
  subscription_id = "cc57cd42-dede-4674-b810-a0fbde41504a"
}


provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "inventoryapp"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "kubernetes_deployment" "inventory" {
  metadata {
    name = "inventory-deployment"
    labels = {
      app = "inventory"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "inventory"
      }
    }

    template {
      metadata {
        labels = {
          app = "inventory"
        }
      }

      spec {
        container {
          name  = "inventory-container"
          image = "atulkamble.azurecr.io/aks-python-app" # Replace with your actual image
          port {
            container_port = 5000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "inventory" {
  metadata {
    name = "inventory-service"
    labels = {
      app = "inventory"
    }
  }

  spec {
    selector = {
      app = "inventory"
    }

    port {
      port        = 80
      target_port = 5000
    }

    type = "LoadBalancer"
  }
}
