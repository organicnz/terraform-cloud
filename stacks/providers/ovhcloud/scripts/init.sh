#!/bin/bash
set -e

# Terraform Initialization Script

echo "🚀 Initializing Terraform for OVHcloud VPS..."

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    echo "Visit: https://www.terraform.io/downloads"
    exit 1
fi

# Check Terraform version
REQUIRED_VERSION="1.5.0"
CURRENT_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
echo "✓ Terraform version: $CURRENT_VERSION"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "⚠️  terraform.tfvars not found"
    echo "Creating from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "✓ Created terraform.tfvars"
    echo "⚠️  Please edit terraform.tfvars with your credentials before proceeding"
    exit 0
fi

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init -upgrade

# Validate configuration
echo "✅ Validating configuration..."
terraform validate

# Format code
echo "🎨 Formatting code..."
terraform fmt -recursive

echo ""
echo "✅ Initialization complete!"
echo ""
echo "Next steps:"
echo "  1. Review your terraform.tfvars file"
echo "  2. Run: terraform plan"
echo "  3. Run: terraform apply"
echo ""
