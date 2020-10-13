.PHONY: build get-variable-path test-run-sh test-run-only-sh test-view docker-down docker-pg docker-pg-connect compress

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
.EXPORT_ALL_VARIABLES:
SHELL := /bin/bash

VERSION := 0.0.1
GIT_BRANCH := $(shell git symbolic-ref --short HEAD)
GIT_COMMIT := $(shell git rev-list -1 HEAD)

BIN_DIR := bin
BIN_FILE := $(BIN_DIR)/vaultify
DEMO_DIR := demo
PGPASSWORD := super-secret-password
DEMO_VAULT := $(DEMO_DIR)/vault
DEMO_VAULT_KEY := $(DEMO_DIR)/key

MODULE_BASE := github.com/datalyze-solutions/vaultify
# disable dynamic linking of the binary to be runnable on any linux (e.g. ubuntu and alpine)
# https://stackoverflow.com/questions/36279253/go-compiled-binary-wont-run-in-an-alpine-docker-container-on-ubuntu-host
BUILD_VARS := CGO_ENABLED=0 GOOS=linux GARCH=amd64
LDFLAGS = -ldflags "-w -s -X ${MODULE_BASE}/cmd.version=$(VERSION) -X ${MODULE_BASE}/cmd.gitCommit=$(GIT_COMMIT) -X ${MODULE_BASE}/cmd.gitBranch=$(GIT_BRANCH)"

DEFAULT_FLAGS := --vaultFile $(DEMO_VAULT) --vaultKeyFile $(DEMO_VAULT_KEY)

version:
	@echo "Version: $(VERSION), Branch: $(GIT_BRANCH), Commit: $(GIT_COMMIT)"

build:
	mkdir -p $(BIN_DIR)
	$(BUILD_VARS) go build ${LDFLAGS} -o $(BIN_DIR)

view-linked-libs:
	ldd $(BIN_FILE) || true

compress:
	upx $(BIN_FILE)
	upx -t $(BIN_FILE)

test:
	go test -v .

get-variable-path:
	go tool nm ./vaultify | grep gitCommit

test-run-sh:
	$(BIN_FILE) $(DEFAULT_FLAGS) --demo run sh -c "export | grep VAULTIFY"

test-run-only-sh:
	$(BIN_FILE) $(DEFAULT_FLAGS) --demo run-only sh -c "export | grep VAULTIFY"

test-view:
	$(BIN_FILE) $(DEFAULT_FLAGS) view

test-version:
	$(BIN_FILE) $(DEFAULT_FLAGS) version

test-docker-down:
	docker container stop vaultify-db || true

test-docker-pg: docker-down
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

test-docker-pg-connect:
	docker exec -it vaultify-db \
		psql -U tester -d tester -h localhost -p 5432 -c "SELECT 1 as test"

test-os-runnable:
	docker run -it --rm -v $PWD/bin/:/app:ro alpine /app/vaultify
	docker run -it --rm -v $PWD/bin/:/app:ro busybox /app/vaultify
	docker run -it --rm -v $PWD/bin/:/app:ro ubuntu:20.04 /app/vaultify

docker-build:
	docker build -t vaultify .