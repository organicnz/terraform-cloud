# Remote State Backend Configuration
# Uncomment and configure for production use

# Option 1: S3-compatible backend (OVHcloud Object Storage)
# terraform {
#   backend "s3" {
#     bucket                      = "terraform-state"
#     key                         = "ovh-vps/terraform.tfstate"
#     region                      = "gra"
#     endpoint                    = "s3.gra.io.cloud.ovh.net"
#     skip_credentials_validation = true
#     skip_region_validation      = true
#   }
# }

# Option 2: Terraform Cloud
# terraform {
#   cloud {
#     organization = "your-org"
#     workspaces {
#       name = "ovh-vps-production"
#     }
#   }
# }

# Option 3: Local backend with encryption (development only)
terraform {
  backend "local" {
    path = "terraform.tfstate"
    # encrypt = true  # Enable state encryption at rest
    # lock_table = "terraform-ovhcloud-lock"  # Separate lock table per stack
  }
}