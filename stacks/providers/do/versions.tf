terraform {
  required_version = ">= 1.0.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.34.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.4"
    }
  }
}