.PHONY: build

build:
	shoebox build my-desktop --tag stayradiated/desktop:latest --build-dir . --verbose

benji:
	shoebox build my-benji --tag stayradiated/benji:latest --build-dir . --verbose
