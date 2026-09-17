# terraform-cloud orchestrator
ROOT := $(shell pwd)
# Parent of terraform-cloud is the directory containing terraform-* projects
PARENT := $(abspath $(ROOT)/..)
# Monorepo stacks under stacks/providers/
STACKS := hetzner do contabo timeweb cloudflare azure oracle ovhcloud
# Alias names matching original terraform-* directory names
STACK_ALIASES := terraform-hetzner terraform-do terraform-contabo terraform-timeweb terraform-cloudflare terraform-azure terraform-oracle terraform-ovhcloud

.PHONY: help list tui init validate fmt plan output checks clean all validate-all init-all fmt-all plan-all output-all check-all clean-all

help:
	@echo "Usage: make <command> [STACK=<stack-name>]"
	@echo ""
	@echo "Commands:"
	@echo "  list              List all 9 monorepo stacks"
	@echo "  tui               Launch the Rust TUI selector"
	@echo "  init              Initialize Terraform for a stack (STACK=<name>)"
	@echo "  validate          Validate Terraform for a stack (STACK=<name>)"
	@echo "  fmt               Format Terraform for a stack (STACK=<name>)"
	@echo "  plan              Plan Terraform for a stack (STACK=<name>)"
	@echo "  output            Show Terraform outputs for a stack (STACK=<name>)"
	@echo "  checks            Run hygiene checks for a stack (STACK=<name>)"
	@echo "  all               Initialize ALL stacks"
	@echo "  validate-all      Validate ALL stacks"
	@echo "  fmt-all           Format ALL stacks"
	@echo "  plan-all          Plan ALL stacks"
	@echo "  output-all        Show outputs for ALL stacks"
	@echo "  check-all         Run checks ALL stacks"
	@echo "  clean             Remove tfplan files from original terraform-* dirs"
	@echo ""
	@echo "Examples:"
	@echo "  make init STACK=hetzner"
	@echo "  make all"
	@echo "  make validate STACK=do"

list:
	@echo "9 stacks:" && \
	for s in $(STACKS); do \
		echo "  - $$s:"; \
		(cargo run -q -p cloud-tui -- --list 2>/dev/null | grep "$$s" | head -1) || \
		echo "    dir=$(ROOT)/stacks/providers/$$s"; \
	done

tui:
	cargo run -p cloud-tui

# Per-stack operations (requires STACK=<name>)
init:
	@if [ -z "$(STACK)" ]; then \
		echo "Error: STACK=<name> required. Available: $(STACKS)"; \
		exit 1; \
	fi
	@# Check by stack name first, then by alias
	@stack_dir="$(ROOT)/stacks/providers/$(STACK)"; \
	if [ -d "$$stack_dir" ]; then \
		cd $$stack_dir && terraform init; \
	elif echo "$(STACK_ALIASES)" | grep -qw "$(STACK)"; then \
		alias="$${echo "$(STACK_ALIASES)" | grep -w "$(STACK)" | cut -d' ' -f1}"; \
		cd $(PARENT)/$$alias && terraform init; \
	else \
		echo "Error: '$STACK' not found. Available: $(STACKS)"; \
		exit 1; \
	fi

validate:
	@if [ -z "$(STACK)" ]; then \
		echo "Error: STACK=<name> required. Available: $(STACKS)"; \
		exit 1; \
	fi
	@stack_dir="$(ROOT)/stacks/providers/$(STACK)"; \
	if [ -d "$$stack_dir" ]; then \
		cd $$stack_dir && terraform validate; \
	elif echo "$(STACK_ALIASES)" | grep -qw "$(STACK)"; then \
		alias="$${echo "$(STACK_ALIASES)" | grep -w "$(STACK)" | cut -d' ' -f1}"; \
		cd $(PARENT)/$$alias && terraform validate; \
	else \
		echo "Error: '$STACK' not found. Available: $(STACKS)"; \
		exit 1; \
	fi

fmt:
	@if [ -z "$(STACK)" ]; then \
		echo "Error: STACK=<name> required. Available: $(STACKS)"; \
		exit 1; \
	fi
	@stack_dir="$(ROOT)/stacks/providers/$(STACK)"; \
	if [ -d "$$stack_dir" ]; then \
		cd $$stack_dir && terraform fmt -check -recursive -diff; \
	elif echo "$(STACK_ALIASES)" | grep -qw "$(STACK)"; then \
		alias="$${echo "$(STACK_ALIASES)" | grep -w "$(STACK)" | cut -d' ' -f1}"; \
		cd $(PARENT)/$$alias && terraform fmt -check -recursive -diff; \
	else \
		echo "Error: '$STACK' not found. Available: $(STACKS)"; \
		exit 1; \
	fi

plan:
	@if [ -z "$(STACK)" ]; then \
		echo "Error: STACK=<name> required. Available: $(STACKS)"; \
		exit 1; \
	fi
	@stack_dir="$(ROOT)/stacks/providers/$(STACK)"; \
	if [ -d "$$stack_dir" ]; then \
		cd $$stack_dir && terraform plan -out=tfplan; \
	elif echo "$(STACK_ALIASES)" | grep -qw "$(STACK)"; then \
		alias="$${echo "$(STACK_ALIASES)" | grep -w "$(STACK)" | cut -d' ' -f1}"; \
		cd $(PARENT)/$$alias && terraform plan -out=tfplan; \
	else \
		echo "Error: '$STACK' not found. Available: $(STACKS)"; \
		exit 1; \
	fi

output:
	@if [ -z "$(STACK)" ]; then \
		echo "Error: STACK=<name> required. Available: $(STACKS)"; \
		exit 1; \
	fi
	@stack_dir="$(ROOT)/stacks/providers/$(STACK)"; \
	if [ -d "$$stack_dir" ]; then \
		cd $$stack_dir && terraform output -json | head -c 4000; echo; \
	elif echo "$(STACK_ALIASES)" | grep -qw "$(STACK)"; then \
		alias="$${echo "$(STACK_ALIASES)" | grep -w "$(STACK)" | cut -d' ' -f1}"; \
		cd $(PARENT)/$$alias && terraform output -json | head -c 4000; echo; \
	else \
		echo "Error: '$STACK' not found. Available: $(STACKS)"; \
		exit 1; \
	fi

checks:
	@if [ -z "$(STACK)" ]; then \
		echo "Error: STACK=<name> required. Available: $(STACKS)"; \
		exit 1; \
	fi
	@stack_dir="$(ROOT)/stacks/providers/$(STACK)"; \
	if [ -d "$$stack_dir" ]; then \
		cargo run -q -p cloud-tui -- --checks $(STACK); \
	elif echo "$(STACK_ALIASES)" | grep -qw "$(STACK)"; then \
		alias="$${echo "$(STACK_ALIASES)" | grep -w "$(STACK)" | cut -d' ' -f1}"; \
		cargo run -q -p cloud-tui -- --checks $$alias; \
	else \
		echo "Error: '$STACK' not found. Available: $(STACKS)"; \
		exit 1; \
	fi

# All-stacks operations
all: init-all

init-all:
	@for stack in $(STACKS); do \
		echo "=== Initializing $$stack ==="; \
		stack_dir="$(ROOT)/stacks/providers/$$stack"; \
		if [ -d "$$stack_dir" ]; then \
			cd $$stack_dir && terraform init 2>&1 | tail -3; \
		else \
			echo "  skipping (not found)"; \
		fi; \
	done

validate-all:
	@for stack in $(STACKS); do \
		echo "=== Validating $$stack ==="; \
		stack_dir="$(ROOT)/stacks/providers/$$stack"; \
		if [ -d "$$stack_dir" ]; then \
			cd $$stack_dir && terraform validate 2>&1 | head -1; \
		else \
			echo "  skipping (not found)"; \
		fi; \
	done

fmt-all:
	@for stack in $(STACKS); do \
		echo "=== Formatting $$stack ==="; \
		stack_dir="$(ROOT)/stacks/providers/$$stack"; \
		if [ -d "$$stack_dir" ]; then \
			cd $$stack_dir && terraform fmt -check -recursive -diff 2>&1 | head -3; \
		else \
			echo "  skipping (not found)"; \
		fi; \
	done

plan-all:
	@for stack in $(STACKS); do \
		echo "=== Planning $$stack ==="; \
		stack_dir="$(ROOT)/stacks/providers/$$stack"; \
		if [ -d "$$stack_dir" ]; then \
			cd $$stack_dir && terraform plan -out=tfplan 2>&1 | tail -3; \
		else \
			echo "  skipping (not found)"; \
		fi; \
	done

output-all:
	@for stack in $(STACKS); do \
		echo "=== Outputs $$stack ==="; \
		stack_dir="$(ROOT)/stacks/providers/$$stack"; \
		if [ -d "$$stack_dir" ]; then \
			cd $$stack_dir && terraform output -json 2>&1 | head -c 2000; echo; \
		else \
			echo "  skipping (not found)"; \
		fi; \
	done

check-all:
	@for stack in $(STACKS); do \
		echo "=== Checking $$stack ==="; \
		(cargo run -q -p cloud-tui -- --checks $$stack 2>&1 | tail -5); \
	done

clean:
	@find $(PARENT)/terraform-* -maxdepth 1 -name "tfplan" -delete 2>/dev/null; true