.PHONY: init plan apply destroy fmt validate lint clean

# Terraform commands
init:
	cd infrastructure && terraform init

plan:
	cd infrastructure && terraform plan -out=tfplan

apply:
	cd infrastructure && terraform apply tfplan

destroy:
	cd infrastructure && terraform destroy

fmt:
	cd infrastructure && terraform fmt -recursive

validate:
	cd infrastructure && terraform validate

# Pre-commit hooks
lint:
	pre-commit run --all-files

# Docker commands
docker-build:
	cd application && docker build -t nginx-fargate-demo .

docker-run:
	docker run -p 8080:80 nginx-fargate-demo

# Cost estimation
cost:
	cd infrastructure && infracost breakdown --path .

# Cleanup
clean:
	rm -f infrastructure/tfplan
	rm -f infrastructure/.terraform.lock.hcl
	rm -rf infrastructure/.terraform

# Help
help:
	@echo "Available targets:"
	@echo "  init       - Initialize Terraform"
	@echo "  plan       - Run Terraform plan"
	@echo "  apply      - Apply Terraform changes"
	@echo "  destroy    - Destroy infrastructure"
	@echo "  fmt        - Format Terraform files"
	@echo "  validate   - Validate Terraform config"
	@echo "  lint       - Run pre-commit hooks"
	@echo "  docker-build - Build Docker image"
	@echo "  docker-run   - Run Docker container locally"
	@echo "  cost       - Estimate infrastructure costs"
	@echo "  clean      - Remove generated files"
