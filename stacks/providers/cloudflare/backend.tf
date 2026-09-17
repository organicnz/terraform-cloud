# Unified stack: explicit local backend per provider (Phase 2).
# Migrate to remote (s3 + lock) per stack in Phase 3.

terraform {
  # local backend for development; each stack has independent state
  backend "local" {
    path = "terraform.tfstate"
    # encrypt = true  # Enable state encryption at rest
    # lock_table = "terraform-cloudflare-lock"  # Separate lock table per stack
  }
}

# Per-stack remote backend (S3 + DynamoDB) - enable when ready:
# terraform {
#   backend "s3" {
#     bucket         = "terraform-states-prod"
#     key            = "cloudflare/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-locks"
#     content_type   = "application/octet-stream"
#   }
# }