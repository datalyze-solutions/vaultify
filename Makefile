.PHONY: build get-variable-path test-run-sh test-run-only-sh test-view docker-down docker-pg docker-pg-connect compress

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
.EXPORT_ALL_VARIABLES:
SHELL := /bin/bash

VERSION = $(shell cat .version)
GIT_BRANCH := $(shell git symbolic-ref --short HEAD)
GIT_COMMIT := $(shell git rev-list -1 HEAD)

BUILD_PLATFORMS ?= linux/amd64,linux/arm64
# BUILD_PLATFORMS ?= linux/amd64
# BUILD_PLATFORMS ?= linux/arm64

GOOS ?= linux
# targetplattform will be passeds as ARG during build
TARGETPLATFORM ?= linux/amd64
# remove linux/ from ARG TARGETPLATTFORM passed via --plattform ARG
GOARCH ?= $(TARGETARCH)
# GOARCH ?= amd64
BUILD_VARS = CGO_ENABLED=0 GOOS=$(GOOS) GARCH=$(GOARCH)
LDFLAGS = -ldflags "-w -s -X ${MODULE_BASE}/cmd.version=$(VERSION) -X ${MODULE_BASE}/cmd.gitCommit=$(GIT_COMMIT) -X ${MODULE_BASE}/cmd.gitBranch=$(GIT_BRANCH)"

BIN_DIR ?= bin/$(GOARCH)
BIN_FILE := $(BIN_DIR)/vaultify
DEMO_DIR := demo
PGPASSWORD := super-secret-password
DEMO_VAULT := $(DEMO_DIR)/vault
DEMO_VAULT_KEY := $(DEMO_DIR)/key

IMAGE_NAME := datalyze/vaultify
IMAGE_TAG := latest

# COMPOSE_DOCKER_CLI_BUILD = 1
# DOCKER_BUILDKIT = 1
# DOCKER_DEFAULT_PLATFORM ?= $(BUILD_PLATTFORMS)

EDITOR := nano

MODULE_BASE := github.com/datalyze-solutions/vaultify
# disable dynamic linking of the binary to be runnable on any linux (e.g. ubuntu and alpine)
# https://stackoverflow.com/questions/36279253/go-compiled-binary-wont-run-in-an-alpine-docker-container-on-ubuntu-host


DEFAULT_FLAGS := --vaultFile $(DEMO_VAULT) --vaultKeyFile $(DEMO_VAULT_KEY)
BUILD_FILE = stack.yaml
BUILDX = docker buildx bake --set *.platform=$(BUILD_PLATFORMS) --pull --progress=plain --file $(BUILD_FILE)

arch:
	@echo "Target: $(TARGETPLATFORM), arch: $(TARGETARCH), build-vars: $(BUILD_VARS)"

version:
	@echo "Version: $(VERSION), Branch: $(GIT_BRANCH), Commit: $(GIT_COMMIT)"

version-build-up:
	echo $(VERSION)
	echo $(VERSION) | awk -F. '{$$NF = $$NF + 1;} 1' | sed 's/ /./g' > .version
	cat .version

deps:
	go get ./...

build: arch
	mkdir -p $(BIN_DIR)
	$(BUILD_VARS) go build ${LDFLAGS} -o $(BIN_DIR)

build-arm: TARGETPLATFORM=linux/arm64
build-arm: arch
	mkdir -p $(BIN_DIR)
	$(BUILD_VARS) go build ${LDFLAGS} -o $(BIN_DIR)

view-linked-libs:
	ldd $(BIN_FILE) || true

compress:
	upx $(BIN_FILE)
	upx -t $(BIN_FILE)

test:
	go test -v .

upgrade-dependencies:
	go get -u
	go mod tidy

buildx-init:
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx create --name multiarch
	docker buildx use multiarch
	docker buildx inspect --bootstrap

buildx-use:
	docker buildx use multiarch

buildx-config:
	$(BUILDX) --print

buildx-build: #version-build-up
	$(BUILDX)
# docker buildx build --platform $(BUILD_PLATFORMS) --progress=plain --push --tag $(IMAGE_NAME):$(IMAGE_TAG) .

buildx-push:
	$(BUILDX) --push

build-docker-local: #version-build-up
	docker build --platform linux/amd64 --tag $(IMAGE_NAME):$(IMAGE_TAG) .

get-variable-path:
	go tool nm ./vaultify | grep gitCommit

vault-edit-demo:
	ansible-vault edit $(DEMO_VAULT) --vault-password-file $(DEMO_VAULT_KEY)

vet:
	go vet -n

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
		-e POSTGRES_PASSWORD="<<DB_PASSWORD>>" \
		-e POSTGRES_USER=tester \
		-e PGPASSWORD="<<DB_PASSWORD>>" \
		--entrypoint /vaultify \
		--name vaultify-db \
		postgres \
		--debug run docker-entrypoint.sh postgres

test-docker-pg-connect:
	docker exec -it vaultify-db \
		psql -U tester -d tester -h localhost -p 5432 -c "SELECT 1 as test"

test-docker-compose:
	docker-compose -f demo/docker-compose.yaml up -d
	docker wait vaultify-db-client
	docker-compose -f demo/docker-compose.yaml logs client
	docker-compose -f demo/docker-compose.yaml down --volume --remove-orphans

test-os-runnable:
	docker run -it --rm -v $$PWD/bin/:/app:ro alpine /app/vaultify run-only echo "It runs!"
	docker run -it --rm -v $$PWD/bin/:/app:ro busybox /app/vaultify run-only echo "It runs!"
	docker run -it --rm -v $$PWD/bin/:/app:ro ubuntu:20.04 /app/vaultify run-only echo "It runs!"

test-docker-swarm-deploy:
	docker stack deploy -c $(DEMO_DIR)/swarm.yaml vaultify-test
	docker service logs -f vaultify-test_client

test-docker-swarm-rm:
	docker stack rm vaultify-test

test-docker-swarm-clean:
	docker volume rm vaultify-test_vaultify-bin

test-docker:
	docker run -it --rm -v $$PWD/demo:/etc/vault:ro -v $$PWD/bin:/vaultify:ro alpine sh

test-docker-node:
	docker run -it --rm -v $$PWD/demo/node-server:/app -v vaultify_node_modules:/app/node_modules node:13-alpine npm install --prefix /app
	docker run -it --rm -v $$PWD/demo:/etc/vault:ro -v $$PWD/bin:/vaultify:ro -v $$PWD/demo/node-server:/app -v vaultify_node_modules:/app/node_modules -p 3000:3000 node:13-alpine /vaultify/vaultify --demo run-sub-sh npm start --prefix /app