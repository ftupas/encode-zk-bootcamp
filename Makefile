.PHONY: build test clean deploy

build:
	$(MAKE) clean
	protostar build

clean:
	rm -rf build
	mkdir build

test:
	protostar test

deploy:
	protostar deploy ./build/$(contract).json --inputs $(constructor_args) --network alpha-goerli
