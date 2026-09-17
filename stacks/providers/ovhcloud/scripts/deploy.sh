#!/bin/bash
set -e

# Terraform Deployment Script with Safety Checks

ENVIRONMENT=${1:-production}
AUTO_APPROVE=${2:-false}

echo "🚀 Deploying OVHcloud VPS to $ENVIRONMENT environment..."

# Safety check for production
if [ "$ENVIRONMENT" = "production" ] && [ "$AUTO_APPROVE" = "true" ]; then
    echo "❌ Auto-approve is not allowed for production deployments"
    echo "Please review the plan manually and approve interactively"
    exit 1
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars not found"
    echo "Run: ./scripts/init.sh first"
    exit 1
fi

# Validate configuration
echo "✅ Validating configuration..."
terraform validate

# Run security scan if tfsec is available
if command -v tfsec &> /dev/null; then
    echo "🔒 Running security scan..."
    tfsec . || echo "⚠️  Security issues found, please review"
fi

# Create plan
echo "📋 Creating execution plan..."
terraform plan -out=tfplan

# Show plan summary
echo ""
echo "📊 Plan Summary:"
terraform show -json tfplan | jq -r '.resource_changes[] | "\(.change.actions[0]) \(.type).\(.name)"' || true

# Apply changes
if [ "$AUTO_APPROVE" = "true" ]; then
    echo "⚡ Applying changes automatically..."
    terraform apply tfplan
else
    echo ""
    echo "Review the plan above and confirm to proceed..."
    terraform apply tfplan
fi

# Show outputs
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Connection Information:"
terraform output -json | jq -r '.connection_info.value | "IP: \(.ip)\nSSH: \(.ssh)\nRegion: \(.region)\nStatus: \(.status)"'

# Cleanup
rm -f tfplan

echo ""
echo "🎉 Done!"
