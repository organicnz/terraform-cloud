# Unified stack: explicit local backend per provider (Phase 2).
# Migrate to remote (s3 + lock) per stack in Phase 3.

terraform {
  # local backend for development; each stack has independent state
  backend "local" {
    path = "terraform.tfstate"
    # encrypt = true  # Enable state encryption at rest
    # lock_table = "terraform-azure-lock"  # Separate lock table per stack
  }
}

# Per-stack remote backend (S3 + DynamoDB) - enable when ready:
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "tfstate"
#     storage_account_name = "azure-tfstate-storage"
#     container_name       = "tfstate"
#     key                  = "azure/terraform.tfstate"
#   }
# }