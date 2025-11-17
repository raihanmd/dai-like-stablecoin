// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Constants} from "./Constants.s.sol";

import {PythDeploy} from "../../script/pyth/PythDeploy.s.sol";
import {ERC20Deploy} from "../../script/erc20/ERC20Deploy.s.sol";

/**
 * @dev All the constants come from Constants.s.sol
 */
contract Config is Constants, Script {
    error Config__InvalidChainId();

    ERC20Deploy erc20Deployer;

    struct NetworkConfig {
        address dscContract;
        address pythContract;
        address[] collateralTokens;
        bytes32[] priceFeeds;
        uint256 pythMaxAge;
        bool exist;
    }

    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        erc20Deployer = new ERC20Deploy();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfig(msg.sender);
    }

    function getConfig(address _deployer) public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid, _deployer);
    }

    function setConfig(uint256 chainId, NetworkConfig memory networkConfig) public {
        networkConfigs[chainId] = networkConfig;
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        return getConfigByChainId(chainId, msg.sender);
    }

    function getConfigByChainId(uint256 chainId, address _deployer) public returns (NetworkConfig memory) {
        if (block.chainid == LOCAL_CHAIN_ID) return getOrCreateAnvilEthConfig(_deployer);
        if (block.chainid == BASE_SEPOLIA_CHAIN_ID) return getBaseSepoliaConfig();
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) return getEthSepoliaConfig();

        NetworkConfig memory config = networkConfigs[chainId];
        if (!config.exist) revert Config__InvalidChainId();
        return config;
    }

    function getBaseSepoliaConfig() public returns (NetworkConfig memory) {
        address[] memory collateralTokens = new address[](2);

        ERC20 wethFake = erc20Deployer.deploy(msg.sender, "Wrapped Ethereum", "WETH");
        ERC20 wbtcFake = erc20Deployer.deploy(msg.sender, "Wrapped Bitcoin", "WBTC");

        collateralTokens[0] = address(wethFake);
        collateralTokens[1] = address(wbtcFake);

        bytes32[] memory priceFeeds = new bytes32[](2);
        priceFeeds[0] = 0x9d4294bbcd1174d6f2003ec365831e64cc31d9f6f15a2b85399db8d5000960f6;
        priceFeeds[1] = 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43;

        return NetworkConfig({
            dscContract: 0x0000000000000000000000000000000000000000,
            pythContract: 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729,
            collateralTokens: collateralTokens,
            priceFeeds: priceFeeds,
            pythMaxAge: 60 * 60 * 24 * 7,
            exist: true
        });
    }

    function getEthSepoliaConfig() public returns (NetworkConfig memory) {
        address[] memory collateralTokens = new address[](2);

        ERC20 wethFake = erc20Deployer.deploy(msg.sender, "Wrapped Ethereum", "WETH");
        ERC20 wbtcFake = erc20Deployer.deploy(msg.sender, "Wrapped Bitcoin", "WBTC");

        collateralTokens[0] = address(wethFake);
        collateralTokens[1] = address(wbtcFake);

        bytes32[] memory priceFeeds = new bytes32[](2);
        priceFeeds[0] = 0x9d4294bbcd1174d6f2003ec365831e64cc31d9f6f15a2b85399db8d5000960f6;
        priceFeeds[1] = 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43;

        return NetworkConfig({
            dscContract: 0x0000000000000000000000000000000000000000,
            pythContract: 0xDd24F84d36BF92C65F92307595335bdFab5Bbd21,
            collateralTokens: collateralTokens,
            priceFeeds: priceFeeds,
            pythMaxAge: 60 * 60 * 24 * 7,
            exist: true
        });
    }

    function getOrCreateAnvilEthConfig(address _deployer) public returns (NetworkConfig memory) {
        /**
         * @dev We do the setup for local anvil network here in the base test so that
         * all the unit tests that inherit from this base test can use the deployed contracts
         * and the network config.
         */
        IPyth pyth = new PythDeploy().deploy(_deployer);

        address[] memory collateralTokens = new address[](2);

        ERC20 wethFake = erc20Deployer.deploy(_deployer, "Wrapped Ethereum", "WETH");
        ERC20 wbtcFake = erc20Deployer.deploy(_deployer, "Wrapped Bitcoin", "WBTC");

        collateralTokens[0] = address(wethFake);
        collateralTokens[1] = address(wbtcFake);

        bytes32[] memory priceFeeds = new bytes32[](2);
        priceFeeds[0] = ETH_USD_PRICE_FEED;
        priceFeeds[1] = BTC_USD_PRICE_FEED;

        activeNetworkConfig = NetworkConfig({
            dscContract: 0x0000000000000000000000000000000000000000,
            pythContract: address(pyth),
            collateralTokens: collateralTokens,
            priceFeeds: priceFeeds,
            pythMaxAge: 60,
            exist: true
        });

        return activeNetworkConfig;
    }
}
