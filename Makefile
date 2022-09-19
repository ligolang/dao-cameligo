SHELL := /bin/bash

ligo_compiler=docker run --rm -v "$(PWD)":"$(PWD)" -w "$(PWD)" ligolang/ligo:stable
# ^ Override this variable when you run make command by make <COMMAND> ligo_compiler=<LIGO_EXECUTABLE>
# ^ Otherwise use default one (you'll need docker)
PROTOCOL_OPT=

project_root=--project-root .
# ^ required when using packages

help:
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

compile = $(ligo_compiler) compile contract $(project_root) ./src/$(1) -o ./compiled/$(2) $(3) $(PROTOCOL_OPT)
# ^ compile contract to michelson or micheline

test = $(ligo_compiler) run test $(project_root) ./test/$(1) $(PROTOCOL_OPT)
# ^ run given test file

compile: ## compile contracts
	@if [ ! -d ./compiled ]; then mkdir ./compiled ; fi
	@$(call compile,main.mligo,dao.tz)
	@$(call compile,main.mligo,dao.json,--michelson-format json)

clean: ## clean up
	@rm -rf compiled

deploy: ## deploy
	@if [ ! -f ./scripts/metadata.json ]; then cp scripts/metadata.json.dist \
        scripts/metadata.json ; fi
	@npx ts-node ./scripts/deploy.ts

install: ## install dependencies
	@if [ ! -f ./.env ]; then cp .env.dist .env ; fi
	@$(ligo_compiler) install
	@npm i

compile-lambda: ## compile a lambda (F=./lambdas/empty_operation_list.mligo make compile-lambda)
# ^ helper to compile lambda from a file, used during development of lambdas
ifndef F
	@echo 'please provide an init file (F=)'
else
	@$(ligo_compiler) compile expression $(project_root) cameligo lambda_ --init-file $(F) $(PROTOCOL_OPT)
	# ^ the lambda is expected to be bound to the name 'lambda_'
endif

pack-lambda: ## pack lambda expression (F=./lambdas/empty_operation_list.mligo make pack-lambda)
# ^ helper to get packed lambda and hash
ifndef F
	@echo 'please provide an init file (F=)'
else
	@echo 'Packed:'
	@$(ligo_compiler) run interpret $(project_root) 'Bytes.pack(lambda_)' --init-file $(F) $(PROTOCOL_OPT)
	@echo "Hash (sha256):"
	@$(ligo_compiler) run interpret $(project_root) 'Crypto.sha256(Bytes.pack(lambda_))' --init-file $(F) $(PROTOCOL_OPT)
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
