.PHONY: build generate

build:
	shoebox build my-desktop --tag stayradiated/desktop:latest --build-dir . --verbose

generate:
	shoebox generate my-desktop > Dockerfile

