# Makefile

.PHONY: all

all: install init plan build

TERRAFORM := $(shell pwd)/terraform
TMP ?= /tmp
OS ?= $(shell uname -s | tr '[:upper:]' '[:lower:]')
TERRAFORM_VERSION ?= 0.11.11
TERRAFORM_URL ?= https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_$(OS)_amd64.zip

install: ## Install terraform
	@[ -x $(TERRAFORM) ] || ( \
	echo "Installing terraform $(TERRAFORM_VERSION) ($(OS)) from $(TERRAFORM_URL)" && \
	curl '-#' -fL -o $(TMP)/terraform.zip $(TERRAFORM_URL) && \
	unzip -q -d $(TMP)/ $(TMP)/terraform.zip && \
	mv $(TMP)/terraform $(TERRAFORM) && \
	rm -f $(TMP)/terraform.zip \
	)

init:
	rm -rf .terraform/modules/
	terraform init -reconfigure

plan: init
	terraform plan -refresh=true

build: init
	terraform apply -auto-approve

check: init
	terraform plan -detailed-exitcode

destroy: init
	terraform destroy -force

docs:
	terraform-docs md . > README.md

valid:
	tflint
	terraform fmt -check=true -diff=true
	terraform validate -check-variables=true .
