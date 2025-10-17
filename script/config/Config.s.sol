// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {Constants} from "./Constant.s.sol";

contract Config is Constants, Script {
    error Config__InvalidChainId();

    struct NetworkConfig {
        address wethAddress;
        address wbtcAddress;
        bool exist;
    }

    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_MAINNET_CHAIN_ID] = getMainnetEthConfig();
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        networkConfigs[LISK_SEPOLIA_CHAIN_ID] = geSepoliaLiskConfig();
    }

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function setConfig(
        uint256 chainId,
        NetworkConfig memory networkConfig
    ) public {
        networkConfigs[chainId] = networkConfig;
    }

    function getConfigByChainId(
        uint256 chainId
    ) public view returns (NetworkConfig memory) {
        NetworkConfig memory config = networkConfigs[chainId];
        if (!config.exist) revert Config__InvalidChainId();
        return config;
    }

    function getMainnetEthConfig()
        public
        pure
        returns (NetworkConfig memory mainnetNetworkConfig)
    {
        mainnetNetworkConfig = NetworkConfig({
            wethAddress: 0x0000000000000000000000000000000000000000,
            wbtcAddress: 0x0000000000000000000000000000000000000000,
            exist: true
        });
    }

    function getSepoliaEthConfig()
        public
        pure
        returns (NetworkConfig memory sepoliaEthNetworkConfig)
    {
        sepoliaEthNetworkConfig = NetworkConfig({
            wethAddress: 0x0000000000000000000000000000000000000000,
            wbtcAddress: 0x0000000000000000000000000000000000000000,
            exist: true
        });
    }

    function geSepoliaLiskConfig()
        public
        pure
        returns (NetworkConfig memory sepoliaLiskNetworkConfig)
    {
        sepoliaLiskNetworkConfig = NetworkConfig({
            wethAddress: 0x0000000000000000000000000000000000000000,
            wbtcAddress: 0x0000000000000000000000000000000000000000,
            exist: true
        });
    }

    function getOrCreateAnvilEthConfig()
        public
        pure
        returns (NetworkConfig memory localNetworkConfig)
    {
        localNetworkConfig = NetworkConfig({
            wethAddress: 0x0000000000000000000000000000000000000000,
            wbtcAddress: 0x0000000000000000000000000000000000000000,
            exist: true
        });
    }
}
