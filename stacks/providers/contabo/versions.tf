terraform {
  required_version = ">= 1.0"

  required_providers {
    contabo = {
      source  = "contabo/contabo"
      version = "~> 0.1.26"
    }
  }
}