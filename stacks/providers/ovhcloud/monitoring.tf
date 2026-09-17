# Monitoring and Health Checks

# Local file for VPS metadata (useful for external monitoring)
resource "local_file" "vps_metadata" {
  count    = var.enable_monitoring ? 1 : 0
  filename = "${path.module}/.terraform/vps-metadata.json"
  content = jsonencode({
    service_name = ovh_vps.vps.service_name
    display_name = ovh_vps.vps.display_name
    plan_code    = var.vps_plan_code
    environment  = var.environment
    created_at   = timestamp()
  })

  lifecycle {
    ignore_changes = [content]
  }
}
