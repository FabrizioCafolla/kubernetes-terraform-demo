terraform {
  required_version = ">= 1.6"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.26.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.1"
    }
  }
}
