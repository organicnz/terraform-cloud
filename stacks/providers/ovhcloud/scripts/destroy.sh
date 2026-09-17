#!/bin/bash
set -e

# Terraform Destroy Script with Safety Checks

ENVIRONMENT=${1:-production}
CONFIRM=${2:-false}

echo "⚠️  WARNING: This will destroy all infrastructure in $ENVIRONMENT environment!"

# Extra safety for production
if [ "$ENVIRONMENT" = "production" ]; then
    echo ""
    echo "🚨 PRODUCTION ENVIRONMENT DETECTED 🚨"
    echo ""
    echo "This action will:"
    echo "  - Delete the VPS instance"
    echo "  - Remove all backups"
    echo "  - Delete SSH keys"
    echo "  - Remove all associated resources"
    echo ""
    
    if [ "$CONFIRM" != "yes-destroy-production" ]; then
        echo "To destroy production, run:"
        echo "  ./scripts/destroy.sh production yes-destroy-production"
        exit 1
    fi
fi

# Show what will be destroyed
echo ""
echo "📋 Resources to be destroyed:"
terraform state list

echo ""
read -p "Type 'destroy' to confirm: " confirmation

if [ "$confirmation" != "destroy" ]; then
    echo "❌ Destruction cancelled"
    exit 1
fi

# Create destroy plan
echo "📋 Creating destroy plan..."
terraform plan -destroy -out=tfplan-destroy

# Execute destroy
echo "💥 Destroying infrastructure..."
terraform apply tfplan-destroy

# Cleanup
rm -f tfplan-destroy

echo ""
echo "✅ Infrastructure destroyed"
echo "⚠️  Remember to:"
echo "  - Remove any manual backups"
echo "  - Revoke API credentials if no longer needed"
echo "  - Clean up any external monitoring"
