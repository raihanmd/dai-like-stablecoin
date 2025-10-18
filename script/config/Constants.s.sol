// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

abstract contract Constants {
    address public constant FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    // uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    bytes32 public constant ETH_USD_PRICE_FEED = keccak256(abi.encodePacked("ETH/USD"));
    bytes32 public constant BTC_USD_PRICE_FEED = keccak256(abi.encodePacked("BTC/USD"));

    function getNetworkName(uint256 chainId) public pure returns (string memory) {
        // if (chainId == ETH_MAINNET_CHAIN_ID) return "Ethereum Mainnet";
        if (chainId == BASE_SEPOLIA_CHAIN_ID) return "Base Sepolia";
        if (chainId == ETH_SEPOLIA_CHAIN_ID) return "Ethereum Sepolia";
        if (chainId == LOCAL_CHAIN_ID) return "Local Anvil";
        return "Unknown";
    }
}
