LAMBDA_ZIP := function.zip
SOPS_SECRETS := .enc.env

## bootstrap:🌱 Bootstrap project
.PHONY: bootstrap
bootstrap:
	sops -d ${SOPS_SECRETS} > .env
	poetry install

## run:💻 Run main script locally
.PHONY: run
run:
	@poetry run main

## archive:📦 Archive AWS Lambda function as a zip
.PHONY: archive
archive:
	@rm -f ${LAMBDA_ZIP}
	cd .venv/lib/python3.10/site-packages/ \
		&& zip -r ../../../../${LAMBDA_ZIP} . -x "boto*"
	cd lambda \
		&& zip -g ../${LAMBDA_ZIP} main.py

## deploy:🚀 Deploy a function to AWS Lambda
.PHONY: deploy
deploy: archive
	lambroll \
		--tfstate ${TFSTATE_URL} \
			deploy \
				--src ${LAMBDA_ZIP}

## invoke:💨 Invoke deployed lambda function
.PHONY: invoke
invoke:
	@echo '{}' | lambroll \
		--tfstate ${TFSTATE_URL} \
			invoke \
				--log-tail

.PHONY: help
help: Makefile
	@echo
	@echo " Choose a command"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo
