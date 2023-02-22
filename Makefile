.PHONY: build test clean deploy

build:
	$(MAKE) clean
	protostar build

clean:
	rm -rf build
	mkdir build

test:
	protostar test

declare:
	protostar declare ./build/$(contract).json --account-address $(account_address) --network testnet --max-fee auto

deploy:
	protostar deploy $(class_hash) --inputs $(constructor_args) --account-address $(account_address) --network testnet --max-fee auto --wait-for-acceptance
