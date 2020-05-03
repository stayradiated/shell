.PHONY: build

build:
	# shoebox generate -c ./components -o Dockerfile my-benji
	docker build --squash -t stayradiated/desktop . 
