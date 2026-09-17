terraform {
  required_version = ">= 1.5"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
    # time provider - pinned to avoid deprecation; verify api compatibility
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}
