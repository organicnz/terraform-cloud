.PHONY: help init validate plan apply destroy fmt clean check-free-tier

ENV ?= production
TFVARS := environments/$(ENV)/terraform.tfvars

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform
	terraform init -upgrade

validate: ## Validate configuration
	@./helpers/validate.sh

fmt: ## Format code
	terraform fmt -recursive

plan: validate ## Plan deployment
	terraform plan -var-file=$(TFVARS) -out=tfplan

apply: ## Apply deployment
	terraform apply tfplan
	@rm -f tfplan

deploy: init plan apply ## Full deployment

destroy: ## Destroy infrastructure
	terraform destroy -var-file=$(TFVARS)

clean: ## Clean temporary files
	rm -f tfplan outputs-*.json
	rm -rf .terraform

check-free-tier: ## Check Always Free tier usage
	@./helpers/check-free-tier.sh

output: ## Show outputs
	terraform output

ssh: ## SSH into instance
	@terraform output -raw ssh_command | sh

# Environment-specific targets
prod: ## Deploy to production
	@$(MAKE) deploy ENV=production

staging: ## Deploy to staging
	@$(MAKE) deploy ENV=staging

# Quick commands
up: deploy ## Alias for deploy
down: destroy ## Alias for destroy
