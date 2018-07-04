.PHONY: build

DOCKER_GID := $(shell getent group docker | cut -d: -f 3)

build:
	docker build \
		-t stayradiated/shell \
		--build-arg DOCKER_GID=$(DOCKER_GID) \
		.
