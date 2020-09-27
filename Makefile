.PHONY: build

build:
	shoebox build my-desktop --tag stayradiated/desktop:latest --build-dir . --verbose

build-manual:
	docker build --squash -t stayradiated/desktop:latest .

benji:
	shoebox build my-benji --tag stayradiated/benji:latest --build-dir . --verbose
