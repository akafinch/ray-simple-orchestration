terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 3.8"
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
