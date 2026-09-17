# VM Operations Module - Outputs

output "deallocate_completed" {
  value = var.deallocate_vms ? "VMs deallocated" : "No action taken"
}

output "deallocate_timestamp" {
  value = var.deallocate_vms ? timestamp() : "N/A"
}

output "prepare_destroy_completed" {
  value = var.prepare_destroy ? "Resources prepared for destruction" : "No preparation done"
}

output "operation_summary" {
  value = {
    vms_deallocated      = var.deallocate_vms
    destruction_prepared = var.prepare_destroy
    last_operation_time  = timestamp()
  }
} 