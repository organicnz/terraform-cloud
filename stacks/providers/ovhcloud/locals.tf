# Local values and computed variables

locals {
  # Timestamp for resource tracking
  timestamp = formatdate("YYYY-MM-DD-hhmm", timestamp())

  # Resource naming
  resource_prefix = "${var.project_name}-${var.environment}"

  # Validation flags
  is_production = var.environment == "production"

  # SSH configuration
  ssh_user = "ubuntu"

  # Backup configuration
  backup_retention_days = local.is_production ? 30 : 7
}
