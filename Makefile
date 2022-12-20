SHELL := /bin/bash

ligo_compiler?=docker run --rm -v "$(PWD)":"$(PWD)" -w "$(PWD)" ligolang/ligo:0.57.0
# ^ Override this variable when you run make command by make <COMMAND> ligo_compiler=<LIGO_EXECUTABLE>
# ^ Otherwise use default one (you'll need docker)
protocol_opt?=

project_root=--project-root .
# ^ required when using packages

help:
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

compile = $(ligo_compiler) compile contract $(project_root) ./src/$(1) -o ./compiled/$(2) $(3) $(protocol_opt)
# ^ compile contract to michelson or micheline

test = $(ligo_compiler) run test $(project_root) ./test/$(1) $(protocol_opt)
# ^ run given test file

compile: ## compile contracts
	@if [ ! -d ./compiled ]; then mkdir ./compiled ; fi
	@echo "Compiling contracts..."
	@$(call compile,main.mligo,dao.tz)
	@$(call compile,main.mligo,dao.json,--michelson-format json)
	@echo "Compiled contracts"

clean: ## clean up
	@rm -rf compiled

deploy: node_modules deploy.js

deploy.js:
	@if [ ! -f ./deploy/metadata.json ]; then cp deploy/metadata.json.dist deploy/metadata.json ; fi
	@echo "Running deploy script\n"
	@cd deploy && npm start

node_modules:
	@echo "Installing deploy script dependencies"
	@cd deploy && npm install
	@echo ""

install: ## install dependencies
	@$(ligo_compiler) install

compile-lambda: ## compile a lambda (F=./lambdas/empty_operation_list.mligo make compile-lambda)
# ^ helper to compile lambda from a file, used during development of lambdas
ifndef F
	@echo 'please provide an init file (F=)'
else
	@$(ligo_compiler) compile expression $(project_root) cameligo lambda_ --init-file $(F) $(protocol_opt)
	# ^ the lambda is expected to be bound to the name 'lambda_'
endif

pack-lambda: ## pack lambda expression (F=./lambdas/empty_operation_list.mligo make pack-lambda)
# ^ helper to get packed lambda and hash
ifndef F
	@echo 'please provide an init file (F=)'
else
	@echo 'Packed:'
	@$(ligo_compiler) run interpret $(project_root) 'Bytes.pack(lambda_)' --init-file $(F) $(protocol_opt)
	@echo "Hash (sha256):"
	@$(ligo_compiler) run interpret $(project_root) 'Crypto.sha256(Bytes.pack(lambda_))' --init-file $(F) $(protocol_opt)
endif

.PHONY: test
test: ## run tests (SUITE=propose make test)
ifndef SUITE
	@$(call test,cancel.test.mligo)
	@$(call test,end_vote.test.mligo)
	@$(call test,execute.test.mligo)
	@$(call test,lock.test.mligo)
	@$(call test,propose.test.mligo)
	@$(call test,release.test.mligo)
	@$(call test,vote.test.mligo)
else
	@$(call test,$(SUITE).test.mligo)
endif

lint: ## lint code
	@npx eslint ./scripts --ext .ts

sandbox-start: ## start sandbox
	@./scripts/run-sandbox

sandbox-stop: ## stop sandbox
	@docker stop sandbox
