TERRAFORM := terraform
TFLINT := tflint

## lint:🔍 Check validation and linting
.PHONY: lint
lint:
	$(TERRAFORM) validate
	$(TFLINT)

## plan:📜 plan
.PHONY: plan
plan: lint
	$(TERRAFORM) plan | less -R

## apply:🚀 apply
.PHONY: apply
apply: lint
	$(TERRAFORM) apply

.PHONY: help
help: Makefile
	@echo
	@echo " Choose a command"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo
