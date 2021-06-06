.PHONY: build build-manual benji chromebook

build:
	shoebox build my-desktop --tag stayradiated/desktop:latest --build-dir . --verbose

build-manual:
	docker build --squash -t stayradiated/desktop:latest .

benji:
	shoebox build my-benji --tag stayradiated/benji:latest --build-dir . --verbose

chromebook:
	shoebox build my-chromebook --tag stayradiated/chromebook:latest --build-dir . --verbose

desktop-minimal:
	shoebox build my-desktop-minimal --tag stayradiated/desktop-minimal:latest --build-dir . --verbose
