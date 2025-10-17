// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {MockPyth} from "@pythnetwork/pyth-sdk-solidity/MockPyth.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Constants} from "./Constant.s.sol";
import {MockERC20} from "../../src/mock/MockERC20.sol";

contract Config is Constants, Script {
    error Config__InvalidChainId();

    MockPyth public pyth;

    struct NetworkConfig {
        address pythContract;
        address dscAddress;
        address[] colateralTokens;
        bytes32[] priceFeeds;
        bool exist;
    }

    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_MAINNET_CHAIN_ID] = getMainnetEthConfig();
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        networkConfigs[LISK_SEPOLIA_CHAIN_ID] = geSepoliaLiskConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function setConfig(uint256 chainId, NetworkConfig memory networkConfig) public {
        networkConfigs[chainId] = networkConfig;
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (block.chainid == LOCAL_CHAIN_ID) return getOrCreateAnvilEthConfig();

        NetworkConfig memory config = networkConfigs[chainId];
        if (!config.exist) revert Config__InvalidChainId();
        return config;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory mainnetNetworkConfig) {
        mainnetNetworkConfig = NetworkConfig({
            pythContract: 0x0000000000000000000000000000000000000000,
            dscAddress: 0x0000000000000000000000000000000000000000,
            colateralTokens: new address[](0),
            priceFeeds: new bytes32[](0),
            exist: true
        });
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory sepoliaEthNetworkConfig) {
        sepoliaEthNetworkConfig = NetworkConfig({
            pythContract: 0x0000000000000000000000000000000000000000,
            dscAddress: 0x0000000000000000000000000000000000000000,
            colateralTokens: new address[](0),
            priceFeeds: new bytes32[](0),
            exist: true
        });
    }

    function geSepoliaLiskConfig() public pure returns (NetworkConfig memory sepoliaLiskNetworkConfig) {
        sepoliaLiskNetworkConfig = NetworkConfig({
            pythContract: 0x0000000000000000000000000000000000000000,
            dscAddress: 0x0000000000000000000000000000000000000000,
            colateralTokens: new address[](0),
            priceFeeds: new bytes32[](0),
            exist: true
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory localNetworkConfig) {
        pyth = new MockPyth(60, 1);

        address[] memory colateralTokens;
        MockERC20 tokenA = new MockERC20("Mock Token A", "MTA");
        MockERC20 tokenB = new MockERC20("Mock Token B", "MTB");

        colateralTokens[0] = address(tokenA);
        colateralTokens[1] = address(tokenB);

        bytes32[] memory priceFeeds;
        priceFeeds[0] = bytes32(uint256(0x1));
        priceFeeds[1] = bytes32(uint256(0x2));

        localNetworkConfig = NetworkConfig({
            pythContract: address(pyth),
            dscAddress: 0x0000000000000000000000000000000000000000,
            colateralTokens: colateralTokens,
            priceFeeds: priceFeeds,
            exist: true
        });
    }
}
