-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil

# help:
# 	@echo "Usage:"
# 	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
# 	@echo ""
# 	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

clean  :; forge clean

install :; forge install && bun install

update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil --chain-id 31337 -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

anvil-sepolia :; anvil --fork-url $(ETH_SEPOLIA_RPC_URL)

deploy:
	@forge script ./script/DSCEngineDeploy.s.sol:DSCEngineDeploy \
	--rpc-url http://localhost:8545 \
	--account anvil \
	--sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
	--broadcast \
	-vvvv

deploy-sepolia:
	@forge script script/DSCEngineDeploy.s.sol:DSCEngineDeploy --rpc-url $(ETH_SEPOLIA_RPC_URL) --account sepolia --sender 0x87406e426cfefd1700997d8e0194e8fce079125e --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

# createSubscription:
# 	@forge script script/Interactions.s.sol:CreateSubscription $(NETWORK_ARGS)


