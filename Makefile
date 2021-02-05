SHELL=/bin/sh

ERGONODE_RELEASE := 1.0.0-beta.8

GIT := git

DOCKER_COMPOSE = docker-compose
DOCKER_COMPOSE_FILE = docker-compose.yml
ifneq (,$(wildcard ./docker-compose.override.yml))
    DOCKER_COMPOSE_FILE := $(DOCKER_COMPOSE_FILE):docker-compose.override.yml
endif
DOCKER_BUILDKIT_VARS = DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1
RUN_DOCKER_COMPOSE = COMPOSE_FILE=$(DOCKER_COMPOSE_FILE) $(DOCKER_COMPOSE)

MESSENGER_CONTAINERS := php-messenger-completeness php-messenger-core php-messenger-export php-messenger-import php-messenger-notification php-messenger-segment

.PHONY: all
all: build start
	docker stats



.PHONY: useskeleton
useskeleton:
	rm -fr frontend/
	$(GIT) clone --branch 'v$(ERGONODE_RELEASE)' -- git@github.com:ergonode/skeleton-frontend.git frontend
	# TODO remove this command once ergonode/skeleton-frontend#10 has been resolved
	$(GIT) --git-dir=frontend/.git --work-tree=frontend/ checkout b0472c9b0baf3b738f8900f1bd361e1e2f33a890
	$(MAKE) all

.PHONY: usesourcecode
usesourcecode:
	rm -fr frontend/
	$(MAKE) all



.PHONY: build
build: frontend/ backend/ ## Build container images
	$(DOCKER_BUILDKIT_VARS) $(RUN_DOCKER_COMPOSE) build

.PHONY: rebuild
rebuild: ## Build container images without a cache
	$(DOCKER_BUILDKIT_VARS) $(RUN_DOCKER_COMPOSE) build --no-cache

backend/:
	$(GIT) clone --branch $(ERGONODE_RELEASE) -- git@github.com:ergonode/backend.git backend

frontend/:
	$(GIT) clone --branch v$(ERGONODE_RELEASE) -- git@github.com:ergonode/frontend.git frontend



.PHONY: start
start: ## Start the service containers in the background
	$(RUN_DOCKER_COMPOSE) up --no-build --remove-orphans --detach

.PHONY: up
up: ## Start the service containers in the foreground
	$(RUN_DOCKER_COMPOSE) up --no-build --remove-orphans

.PHONY: recreate
recreate: ## Recreates all service containers
	$(RUN_DOCKER_COMPOSE) up --no-build --remove-orphans --detach --force-recreate

.PHONY: restart
restart: ## Restart the service contianers
	$(RUN_DOCKER_COMPOSE) restart --timeout 30

.PHONY: stop
stop: ## Stop the service containers running in the background
	$(RUN_DOCKER_COMPOSE) down

.PHONY: status ps
status: ## Show status of service containers
	$(RUN_DOCKER_COMPOSE) ps
ps: status



.PHONY: clean
clean: ## Removes containers, images and volumes from Docker and removes the .env file
	$(RUN_DOCKER_COMPOSE) down -v --rmi=local

.PHONY: cleanvol
cleanvol: ## Clean the container's volumes, will stop running containers first
	$(RUN_DOCKER_COMPOSE) down -v

.PHONY: pristine
pristine: clean ## Same as clean but also removes frontend/ & backend/ directories
	rm -fr backend/ frontend/



.PHONY: logs
logs:
	$(RUN_DOCKER_COMPOSE) logs -f

.PHONY: frontendlogs nuxtlogs nuxtjslogs
frontendlogs:
	$(RUN_DOCKER_COMPOSE) logs -f nuxtjs
nuxtlogs: frontendlogs
nuxtjslogs: frontendlogs

.PHONY: backendlogs
backendlogs:
	$(RUN_DOCKER_COMPOSE) logs -f php

.PHONY: phplogs
phplogs:
	$(RUN_DOCKER_COMPOSE) logs -f php $(MESSENGER_CONTAINERS)

.PHONY: messengerlogs
messengerlogs:
	$(RUN_DOCKER_COMPOSE) logs -f $(MESSENGER_CONTAINERS)



### HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
