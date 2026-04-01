terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 3.8"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
  required_version = ">= 1.6"
}

provider "linode" {
  token       = var.linode_token
  api_version = "v4beta"
}

provider "helm" {
  kubernetes {
    host                   = module.lke.kubeconfig_host
    token                  = module.lke.kubeconfig_token
    cluster_ca_certificate = base64decode(module.lke.kubeconfig_ca)
  }
}

provider "kubernetes" {
  host                   = module.lke.kubeconfig_host
  token                  = module.lke.kubeconfig_token
  cluster_ca_certificate = base64decode(module.lke.kubeconfig_ca)
}
