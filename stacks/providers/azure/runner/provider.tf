terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Local state, kept separate from the parent azure stack.
  # Move to the azurerm backend before running this anywhere shared.
  backend "local" {
    path = "runner.tfstate"
  }
}

provider "azurerm" {
  features {}

  # Pinned explicitly: the parent stack's subscription_id default is mirrored
  # here so this root module can never drift onto a pay-as-you-go subscription.
  subscription_id = var.subscription_id
}
