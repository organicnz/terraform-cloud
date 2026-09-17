# Azure Cleanup Module - Usage Guide

This guide provides step-by-step instructions for using the Azure Cleanup module to discover, plan, and selectively clean up resources in your Azure subscription.

## Overview

The Azure Cleanup module provides a resource-agnostic approach to cleaning up Azure resources:

1. **Discovery Phase**: Scans all resources in your subscription
2. **Planning Phase**: Creates a cleanup plan based on discovered resources
3. **Execution Phase**: Selectively executes the cleanup with optional confirmation steps

## Prerequisites

- Terraform 0.14 or later
- Azure CLI installed and configured
- Sufficient permissions to delete resources in your Azure subscription

## Step 1: Configure Module

Update your `terraform.tfvars` file to configure the module:

```hcl
# Azure Cleanup Module Settings
# Initially, all settings are false
scan_azure_resources = false
plan_azure_cleanup = false
execute_azure_cleanup = false
confirm_each_deletion = true
```

## Step 2: Scan Azure Resources

Set `scan_azure_resources` to `true` in your `terraform.tfvars` file:

```hcl
scan_azure_resources = true
plan_azure_cleanup = false
execute_azure_cleanup = false
```

Run Terraform:

```bash
terraform apply -var-file=terraform.tfvars
```

This will create a `.azure-cleanup` directory containing JSON files with all discovered resources.

## Step 3: Generate Cleanup Plan

Set `plan_azure_cleanup` to `true` in your `terraform.tfvars` file:

```hcl
scan_azure_resources = true
plan_azure_cleanup = true
execute_azure_cleanup = false
```

Run Terraform:

```bash
terraform apply -var-file=terraform.tfvars
```

This will generate a cleanup plan (`cleanup_plan.md`) and an execution script (`execute_cleanup.sh`).

## Step 4: Review the Cleanup Plan

Review the generated cleanup plan at `.azure-cleanup/cleanup_plan.md` to understand what will be deleted.

This is the crucial step where you decide what resources you want to keep or delete.

## Step 5: Execute Cleanup

You have two options for executing the cleanup:

### Option 1: Using Terraform

Set `execute_azure_cleanup` to `true` in your `terraform.tfvars` file:

```hcl
scan_azure_resources = true
plan_azure_cleanup = true
execute_azure_cleanup = true
```

Run Terraform:

```bash
terraform apply -var-file=terraform.tfvars
```

### Option 2: Using the Shell Script Directly

Run the generated script manually:

```bash
./.azure-cleanup/execute_cleanup.sh --confirm
```

Add the `--auto` flag to skip confirmation prompts:

```bash
./.azure-cleanup/execute_cleanup.sh --auto
```

## Cleanup Workflow Recommendations

For maximum safety and control:

1. First, run the scan phase alone and review the discovered resources
2. Next, run the planning phase and carefully review the cleanup plan
3. Finally, run the execution phase with `confirm_each_deletion = true` to confirm each step

## Troubleshooting

### Resource Locks

If resources fail to delete due to locks, the module will attempt to remove them automatically.

### Recovery Services Vaults

These require special handling due to backup items and soft-delete settings. The module includes
specific steps for properly cleaning up these resources.

### Long-Running Deletions

Resource group deletions can take a long time. The module includes waiting logic to monitor 
deletion progress. 