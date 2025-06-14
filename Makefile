.PHONY: build generate

build:
	../shoebox/bin/shoebox build my-desktop --tag stayradiated/desktop:latest --build-dir . --verbose

generate:
	shoebox generate my-desktop > Dockerfile

generate-benji: 
	shoebox generate my-benji > Dockerfile

build-benji:
	../shoebox/bin/shoebox build my-benji --tag stayradiated/benji:latest --build-dir . --verbose
