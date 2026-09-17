# OVHcloud VPS Configuration
# VPS-1: 4 vCores, 8GB RAM, 75GB SSD NVMe

locals {
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
      Region      = var.region
      CreatedAt   = timestamp()
    },
    var.tags
  )

  instance_name = "${var.vps_name}-${var.environment}"
}

# VPS Instance
resource "ovh_vps" "vps" {
  ovh_subsidiary = var.ovh_subsidiary
  display_name   = local.instance_name

  plan = [{
    duration     = "P1M"
    plan_code    = var.vps_plan_code
    pricing_mode = "default"
  }]

  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      plan
    ]
  }
}

# Wait for VPS to be fully operational
resource "time_sleep" "wait_for_vps" {
  depends_on = [ovh_vps.vps]

  create_duration = "60s"
}
