#!/bin/bash
# Check Always Free tier usage

set -e

# Try to get tenancy ID from various sources
if [ -n "${1:-}" ]; then
    TENANCY_ID="$1"
elif [ -f environments/production/terraform.tfvars ]; then
    TENANCY_ID=$(grep tenancy_ocid environments/production/terraform.tfvars | cut -d'"' -f2)
elif [ -n "$TF_VAR_tenancy_ocid" ]; then
    TENANCY_ID="$TF_VAR_tenancy_ocid"
else
    echo "❌ Error: Tenancy OCID not found in production.tfvars or TF_VAR_tenancy_ocid environment variable."
    exit 1
fi

echo "📊 Checking Always Free tier usage for tenancy: ${TENANCY_ID:0:20}..."
echo ""

# Get all ARM instances
oci compute instance list \
  --compartment-id "$TENANCY_ID" \
  --query 'data[?shape==`VM.Standard.A1.Flex` && "lifecycle-state"!=`TERMINATED`].{Name:"display-name", OCPUs:"shape-config".ocpus, Memory:"shape-config"."memory-in-gbs", State:"lifecycle-state"}' \
  --output table

echo ""
echo "Always Free Limits (total per account):"
echo "  OCPUs: 4 total"
echo "  Memory: 24 GB total"
echo "  Storage: 200 GB total"
