.PHONY: build get-variable-path test-run-sh test-run-only-sh test-view docker-down docker-pg docker-pg-connect

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
.EXPORT_ALL_VARIABLES:
SHELL := /bin/bash

# GIT_COMMIT=$(git rev-list -1 HEAD)
VERSION := 0.0.1
BUILD := dev
GIT_COMMIT := dev

BIN_DIR := bin
BIN_FILE := $(BIN_DIR)/vaultify
DEMO_DIR := demo
PGPASSWORD := super-secret-password
DEMO_VAULT := $(DEMO_DIR)/vault
DEMO_VAULT_KEY := $(DEMO_DIR)/key

MODULE_BASE := github.com/datalyze-solutions/vaultify
LDFLAGS = -ldflags "-w -s -X ${MODULE_BASE}/cmd.version=$(VERSION) -X ${MODULE_BASE}/cmd.gitCommit=$(GIT_COMMIT) -X ${MODULE_BASE}/cmd.build=$(BUILD)"

DEFAULT_FLAGS := --vaultFile $(DEMO_VAULT) --vaultKeyFile $(DEMO_VAULT_KEY)

build:
	mkdir -p $(BIN_DIR)
	go build ${LDFLAGS} -o $(BIN_DIR)

get-variable-path:
	go tool nm ./vaultify | grep gitCommit

test-run-sh:
	$(BIN_FILE) $(DEFAULT_FLAGS) --demo run sh -c "export | grep VAULTIFY"

test-run-only-sh:
	$(BIN_FILE) $(DEFAULT_FLAGS) --demo run-only sh -c "export | grep VAULTIFY"

test-view:
	$(BIN_FILE) $(DEFAULT_FLAGS) view

docker-down:
	docker container stop vaultify-db || true

docker-pg: docker-down
	docker run -d --rm \
		-v $$PWD/$(BIN_FILE):/vaultify:ro \
		-v $$PWD/$(DEMO_VAULT):/etc/vault/vault:ro \
		-v $$PWD/$(DEMO_VAULT_KEY):/etc/vault/key:ro \
		-e POSTGRES_PASSWORD={{DB_PASSWORD}} \
		-e POSTGRES_USER=tester \
		-e PGPASSWORD={{DB_PASSWORD}} \
		--entrypoint /vaultify \
		--name vaultify-db \
		postgres:12 \
		--debug run docker-entrypoint.sh postgres

docker-pg-connect:
	docker exec -it vaultify-db \
		psql -U tester -d tester -h localhost -p 5432 -c "SELECT 1 as test"
