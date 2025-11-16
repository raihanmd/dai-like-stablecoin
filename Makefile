-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil

# help:
# 	@echo "Usage:"
# 	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
# 	@echo ""
# 	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install && bun install

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

anvil-sepolia :; anvil --fork-url $(ETH_SEPOLIA_RPC_URL)

deploy:
	@forge script script/DSCEngineDeploy.s.sol:DSCEngineDeploy --broadcast -vvvv --account sepolia --sender 0x87406E426cfEFd1700997D8e0194e8FCe079125e --rpc-url http://localhost:8545

deploy-sepolia:
	@forge script script/DSCEngineDeploy.s.sol:DSCEngineDeploy --rpc-url $(ETH_SEPOLIA_RPC_URL) --account sepolia --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

# createSubscription:
# 	@forge script script/Interactions.s.sol:CreateSubscription $(NETWORK_ARGS)


