# Terraform Contabo Infrastructure Makefile

# Default variables
ENV ?= dev
TERRAFORM_DIR = .
VAR_FILE = environments/$(ENV)/terraform.tfvars

# Color codes for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help init plan apply destroy validate fmt lint clean status outputs

# Default target
help: ## Show this help message
	@echo "Terraform Contabo Infrastructure Management"
	@echo "Usage: make [target] [ENV=environment]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Examples:"
	@echo "  make init                    # Initialize Terraform"
	@echo "  make plan ENV=dev           # Plan changes for dev environment"
	@echo "  make apply ENV=prod         # Apply changes to prod environment"
	@echo "  make destroy ENV=dev        # Destroy dev environment"

init: ## Initialize Terraform working directory
	@echo "$(GREEN)Initializing Terraform...$(NC)"
	@terraform -chdir=$(TERRAFORM_DIR) init
	@echo "$(GREEN)Terraform initialized successfully!$(NC)"

validate: ## Validate Terraform configuration
	@echo "$(GREEN)Validating Terraform configuration...$(NC)"
	@terraform -chdir=$(TERRAFORM_DIR) validate
	@echo "$(GREEN)Configuration is valid!$(NC)"

fmt: ## Format Terraform configuration files
	@echo "$(GREEN)Formatting Terraform files...$(NC)"
	@terraform -chdir=$(TERRAFORM_DIR) fmt -recursive
	@echo "$(GREEN)Files formatted successfully!$(NC)"

plan: validate ## Create and show an execution plan
	@echo "$(GREEN)Creating execution plan for $(ENV) environment...$(NC)"
	@if [ ! -f $(VAR_FILE) ]; then \
		echo "$(RED)Error: Variable file $(VAR_FILE) not found!$(NC)"; \
		echo "$(YELLOW)Available environments:$(NC)"; \
		ls -1 environments/; \
		exit 1; \
	fi
	@terraform -chdir=$(TERRAFORM_DIR) plan -var-file="../$(VAR_FILE)" -out=tfplan-$(ENV)
	@echo "$(GREEN)Plan created successfully! Review the changes above.$(NC)"

apply: ## Apply the Terraform configuration
	@echo "$(GREEN)Applying Terraform configuration for $(ENV) environment...$(NC)"
	@if [ ! -f $(VAR_FILE) ]; then \
		echo "$(RED)Error: Variable file $(VAR_FILE) not found!$(NC)"; \
		exit 1; \
	fi
	@if [ -f tfplan-$(ENV) ]; then \
		terraform -chdir=$(TERRAFORM_DIR) apply tfplan-$(ENV); \
	else \
		terraform -chdir=$(TERRAFORM_DIR) apply -var-file="../$(VAR_FILE)"; \
	fi
	@echo "$(GREEN)Infrastructure deployed successfully!$(NC)"

destroy: ## Destroy Terraform-managed infrastructure
	@echo "$(RED)WARNING: This will destroy all resources in $(ENV) environment!$(NC)"
	@read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ]
	@terraform -chdir=$(TERRAFORM_DIR) destroy -var-file="../$(VAR_FILE)"
	@echo "$(GREEN)Infrastructure destroyed.$(NC)"

status: ## Show current Terraform state
	@echo "$(GREEN)Current Terraform state:$(NC)"
	@terraform -chdir=$(TERRAFORM_DIR) show

outputs: ## Show Terraform outputs
	@echo "$(GREEN)Terraform outputs:$(NC)"
	@terraform -chdir=$(TERRAFORM_DIR) output

clean: ## Clean up temporary files
	@echo "$(GREEN)Cleaning up temporary files...$(NC)"
	@rm -f tfplan-*
	@rm -f *.tfplan
	@rm -f crash.log
	@echo "$(GREEN)Cleanup complete!$(NC)"