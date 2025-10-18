// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";

import {DSCEngineDeploy} from "../script/DSCEngineDeploy.s.sol";
import {Config} from "../script/config/Config.s.sol";
import {Constants} from "../script/config/Constants.s.sol";
import {PythDeploy} from "../script/pyth/PythDeploy.s.sol";
import {PythInteractions} from "../script/pyth/PythInteractions.s.sol";
import {DecentralizedStableCoinDeploy} from "../script/DecentralizedStableCoinDeploy.s.sol";

contract BaseTest is Test, Constants {
    Config.NetworkConfig internal networkConfig;

    function setUpBaseTest() public {
        networkConfig = new Config().getConfig();

        /**
         * @dev We do the setup for local anvil network here in the base test so that
         * all the unit tests that inherit from this base test can use the deployed contracts
         * and the network config.
         */
        if (block.chainid == LOCAL_CHAIN_ID) {
            IPyth pyth = new PythDeploy().deploy(FOUNDRY_DEFAULT_SENDER);
            DecentralizedStableCoin dsc = new DecentralizedStableCoinDeploy().deploy(FOUNDRY_DEFAULT_SENDER);

            PythInteractions pythInteractions = new PythInteractions();

            pythInteractions.createPriceFeed(address(pyth), ETH_USD_PRICE_FEED, 4000, "ETH/USD");
            pythInteractions.createPriceFeed(address(pyth), BTC_USD_PRICE_FEED, 100_000, "BTC/USD");

            address[] memory colateralTokens = new address[](2);

            vm.startBroadcast(FOUNDRY_DEFAULT_SENDER);
            MockERC20 wethFake = new MockERC20("Wrapped Ethereum", "WETH");
            MockERC20 wbtcFake = new MockERC20("Wrapped Bitcoin", "WBTC");
            vm.stopBroadcast();

            colateralTokens[0] = address(wethFake);
            colateralTokens[1] = address(wbtcFake);

            bytes32[] memory priceFeeds = new bytes32[](2);

            priceFeeds[0] = ETH_USD_PRICE_FEED;
            priceFeeds[1] = BTC_USD_PRICE_FEED;

            console2.log("Local Anvil Network Detected. Deploying Mocks and DSC Engine...");

            BaseTest.networkConfig = Config.NetworkConfig({
                pythContract: address(pyth),
                dscAddress: address(dsc),
                colateralTokens: colateralTokens,
                priceFeeds: priceFeeds,
                exist: true
            });
        }
    }
}
