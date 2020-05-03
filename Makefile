.PHONY: build

build:
	# shoebox generate -c ./components -o Dockerfile my-benji
	docker build -t stayradiated/desktop . 
