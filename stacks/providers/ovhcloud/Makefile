.PHONY: help init plan apply destroy validate fmt lint clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize Terraform
	terraform init -upgrade

validate: ## Validate Terraform configuration
	terraform validate
	terraform fmt -check -recursive

fmt: ## Format Terraform files
	terraform fmt -recursive

plan: ## Show Terraform execution plan
	terraform plan -out=tfplan

apply: ## Apply Terraform changes
	terraform apply tfplan

apply-auto: ## Apply Terraform changes without confirmation (use with caution)
	terraform apply -auto-approve

destroy: ## Destroy all Terraform-managed infrastructure
	terraform destroy

destroy-auto: ## Destroy without confirmation (use with extreme caution)
	terraform destroy -auto-approve

output: ## Show Terraform outputs
	terraform output

refresh: ## Refresh Terraform state
	terraform refresh

state-list: ## List resources in state
	terraform state list

lint: ## Run tflint
	@command -v tflint >/dev/null 2>&1 || { echo "tflint not installed. Install from https://github.com/terraform-linters/tflint"; exit 1; }
	tflint --init
	tflint

security: ## Run security scan with tfsec
	@command -v tfsec >/dev/null 2>&1 || { echo "tfsec not installed. Install from https://github.com/aquasecurity/tfsec"; exit 1; }
	tfsec .

docs: ## Generate documentation
	@command -v terraform-docs >/dev/null 2>&1 || { echo "terraform-docs not installed. Install from https://github.com/terraform-docs/terraform-docs"; exit 1; }
	terraform-docs markdown table --output-file README.md --output-mode inject .

clean: ## Clean temporary files
	rm -rf .terraform/
	rm -f tfplan
	rm -f terraform.tfstate.backup
	rm -f .terraform.lock.hcl

check: validate lint security ## Run all checks

all: init validate plan ## Initialize, validate, and plan
