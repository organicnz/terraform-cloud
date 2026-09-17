locals {
  # Script contents as heredocs for better version control and organization

  cleanup_script = <<-EOT
#!/bin/bash

# Remove Terraform state files
rm -f terraform.tfstate 
rm -f terraform.tfstate.backup
rm -f .terraform.lock.hcl

# Delete the .terraform directory
rm -rf .terraform

# Remove generated plan files
rm -f terraform.plan

# Delete backup files
rm -f *.backup
  EOT

  load_env_script = <<-EOT
#!/bin/bash

# Check if .env file exists
if [ ! -f .env ]; then
  echo "Error: .env file not found"
  echo "Please create a .env file with your credentials (see README.md for instructions)"
  exit 1
fi

# Export environment variables from .env
export \$(grep -v '^#' .env | xargs)

echo "Environment variables loaded successfully"
echo "You can now run terraform commands in this shell session"

# If any command is provided as an argument, execute it
if [ $# -gt 0 ]; then
  exec "\$@"
fi
  EOT
}

# Script execution resource for cleanup
resource "null_resource" "cleanup" {
  # This resource can be targeted to run the cleanup
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "bash -c '${local.cleanup_script}'"
  }
}

# Script execution resource for loading environment variables
resource "null_resource" "load_env" {
  # This resource can be targeted to demonstrate loading environment variables
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    # This will only print confirmation - actual env loading requires source
    command = "echo 'To load environment variables, run: source <(echo \"${local.load_env_script}\")'"
  }
}

# Output helper information
output "script_usage" {
  description = "Information about integrated scripts"
  value       = <<-EOT
    Terraform-integrated scripts available:
    
    1. Clean up state files: 
       terraform apply -target=null_resource.cleanup -auto-approve
    
    2. Load environment variables (for the current shell):
       source <(terraform output -raw load_env_script)
  EOT
}

# Output the script content for direct use
output "cleanup_script" {
  description = "Cleanup script content"
  value       = local.cleanup_script
  sensitive   = true
}

output "load_env_script" {
  description = "Environment loading script content"
  value       = local.load_env_script
  sensitive   = true
} 