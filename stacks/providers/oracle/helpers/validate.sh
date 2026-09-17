#!/bin/bash
# Validate Terraform configuration

set -e

echo "🔍 Validating Terraform configuration..."

# Format check
echo "  → Checking format..."
terraform fmt -check -recursive || {
    echo "  ⚠️  Auto-fixing format..."
    terraform fmt -recursive
}

# Validate
echo "  → Validating syntax..."
terraform validate

# Security scan (if tfsec installed)
if command -v tfsec &> /dev/null; then
    echo "  → Running security scan..."
    tfsec . --minimum-severity MEDIUM
fi

echo "✅ Validation complete"
