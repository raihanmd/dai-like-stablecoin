// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {MockPyth} from "@pythnetwork/pyth-sdk-solidity/MockPyth.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Constants} from "./Constants.s.sol";
import {MockERC20} from "../../src/mock/MockERC20.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";

import {DecentralizedStableCoinDeploy} from "../../script/DecentralizedStableCoinDeploy.s.sol";
import {PythDeploy} from "../../script/pyth/PythDeploy.s.sol";

import {PythInteractions} from "../../script/pyth/PythInteractions.s.sol";

/**
 * @dev All the constants come from Constants.s.sol
 */
contract Config is Constants, Script {
    error Config__InvalidChainId();

    IPyth public pyth;
    DecentralizedStableCoin public dsc;

    struct NetworkConfig {
        address pythContract;
        address dscAddress;
        address[] colateralTokens;
        bytes32[] priceFeeds;
        bool exist;
    }

    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[BASE_SEPOLIA_CHAIN_ID] = getBaseSepoliaConfig();
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
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

    function getBaseSepoliaConfig() public returns (NetworkConfig memory mainnetNetworkConfig) {
        dsc = new DecentralizedStableCoinDeploy().deploy(msg.sender);

        mainnetNetworkConfig = NetworkConfig({
            pythContract: 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729,
            dscAddress: address(dsc),
            colateralTokens: new address[](0),
            priceFeeds: new bytes32[](0),
            exist: true
        });
    }

    function getEthSepoliaConfig() public returns (NetworkConfig memory sepoliaEthNetworkConfig) {
        dsc = new DecentralizedStableCoinDeploy().deploy(msg.sender);

        sepoliaEthNetworkConfig = NetworkConfig({
            pythContract: 0xDd24F84d36BF92C65F92307595335bdFab5Bbd21,
            dscAddress: address(dsc),
            colateralTokens: new address[](0),
            priceFeeds: new bytes32[](0),
            exist: true
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory localNetworkConfig) {
        // TODO: I dont think so, the setup should be here or make higher abstraction level for config (in this case for local anvil only)
        console2.log(msg.sender);

        pyth = new PythDeploy().deploy(msg.sender);
        dsc = new DecentralizedStableCoinDeploy().deploy(msg.sender);

        PythInteractions pythInteractions = new PythInteractions();

        pythInteractions.createPriceFeed(address(pyth), ETH_USD_PRICE_FEED, 4000, "ETH/USD");
        pythInteractions.createPriceFeed(address(pyth), BTC_USD_PRICE_FEED, 100_000, "BTC/USD");

        address[] memory colateralTokens = new address[](2);
        vm.startBroadcast(msg.sender);
        MockERC20 wethFake = new MockERC20("Wrapped Ethereum", "WETH");
        MockERC20 wbtcFake = new MockERC20("Wrapped Bitcoin", "WBTC");
        vm.stopBroadcast();

        colateralTokens[0] = address(wethFake);
        colateralTokens[1] = address(wbtcFake);

        bytes32[] memory priceFeeds = new bytes32[](2);
        priceFeeds[0] = ETH_USD_PRICE_FEED;
        priceFeeds[1] = BTC_USD_PRICE_FEED;

        localNetworkConfig = NetworkConfig({
            pythContract: address(pyth),
            dscAddress: address(dsc),
            colateralTokens: colateralTokens,
            priceFeeds: priceFeeds,
            exist: true
        });
    }
}
