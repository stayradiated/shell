# Configuration
DOCKER_USERNAME := stayradiated
DOCKER_BUILD_ARGS := --squash
SHOEBOX := shoebox

# Targets
TARGETS := desktop shell

# Default target
.DEFAULT_GOAL := help

# Phony targets - mark all our targets as phony so they always run
.PHONY: all clean help generate-all build-all \
        $(addprefix generate-,$(TARGETS)) \
        $(addprefix build-,$(TARGETS)) \
        $(addprefix build-,$(addsuffix -tagged,$(TARGETS)))

# Help target
help:
	@echo "Available targets:"
	@echo "  all                 - Generate and build all images"
	@echo "  generate-all        - Generate all Dockerfiles"
	@echo "  build-all           - Build all images"
	@echo "  generate-desktop    - Generate Dockerfile for desktop"
	@echo "  build-desktop       - Generate and build desktop image"
	@echo "  generate-shell      - Generate Dockerfile for shell"
	@echo "  build-shell         - Generate and build shell image"
	@echo "  clean               - Remove generated Dockerfiles"

# All target
all: build-all

# Generate all Dockerfiles
generate-all:
	@for target in $(TARGETS); do \
		$(MAKE) generate-$$target; \
	done

# Build all images
build-all:
	@for target in $(TARGETS); do \
		$(MAKE) build-$$target; \
	done

# Specific generate targets
generate-desktop:
	$(SHOEBOX) generate my-desktop > Dockerfile.desktop
	@echo "Generated Dockerfile.desktop"

generate-shell:
	$(SHOEBOX) generate my-shell > Dockerfile.shell
	@echo "Generated Dockerfile.shell"

# Specific build targets
build-desktop: generate-desktop
	docker build $(DOCKER_BUILD_ARGS) -f Dockerfile.desktop -t $(DOCKER_USERNAME)/desktop:latest .
	@echo "Built $(DOCKER_USERNAME)/desktop:latest"

build-shell: generate-shell
	docker build $(DOCKER_BUILD_ARGS) -f Dockerfile.shell -t $(DOCKER_USERNAME)/shell:latest .
	@echo "Built $(DOCKER_USERNAME)/shell:latest"

# Clean generated files
clean:
	rm -f $(addprefix Dockerfile.,$(TARGETS))
	@echo "Cleaned generated Dockerfiles"

# Optional: Add version/tag support
TAG ?= latest
build-desktop-tagged: generate-desktop
	docker build $(DOCKER_BUILD_ARGS) -f Dockerfile.desktop -t $(DOCKER_USERNAME)/desktop:$(TAG) .
	@echo "Built $(DOCKER_USERNAME)/desktop:$(TAG)"

build-shell-tagged: generate-shell
	docker build $(DOCKER_BUILD_ARGS) -f Dockerfile.shell -t $(DOCKER_USERNAME)/shell:$(TAG) .
	@echo "Built $(DOCKER_USERNAME)/shell:$(TAG)"
