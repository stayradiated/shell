.PHONY: build generate

build:
	../shoebox/bin/shoebox build my-desktop --tag stayradiated/desktop:latest --build-dir . --verbose

generate:
	shoebox generate my-desktop > Dockerfile

generate-benji: 
	shoebox generate my-benji > Dockerfile

build-benji:
	docker build --squash -t stayradiated/benji:latest .
