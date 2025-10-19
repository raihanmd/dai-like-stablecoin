// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

import {Constants} from "./config/Constants.s.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {Config} from "../script/config/Config.s.sol";

import {PythDeploy} from "./pyth/PythDeploy.s.sol";
import {PythInteractions} from "./pyth/PythInteractions.s.sol";
import {DecentralizedStableCoinDeploy} from "./DecentralizedStableCoinDeploy.s.sol";

contract DSCEngineDeploy is Script, Constants {
    function run() public {
        deploy(msg.sender, new Config().getConfig());
    }

    function deploy(address _deployer, Config.NetworkConfig memory networkConfig)
        public
        returns (DSCEngine dscEngine)
    {
        localNetworkSetup(networkConfig);

        DecentralizedStableCoin dsc;

        dsc = new DecentralizedStableCoinDeploy().deploy(_deployer);

        vm.startBroadcast(_deployer);

        dscEngine = new DSCEngine(
            networkConfig.pythContract, address(dsc), networkConfig.collateralTokens, networkConfig.priceFeeds
        );

        dsc.transferOwnership(address(dscEngine));

        vm.stopBroadcast();

        return dscEngine;
    }

    function localNetworkSetup(Config.NetworkConfig memory networkConfig) public {
        if (block.chainid != LOCAL_CHAIN_ID) return;

        PythInteractions pythInteractions = new PythInteractions();

        pythInteractions.createPriceFeed(address(networkConfig.pythContract), ETH_USD_PRICE_FEED, ETH_PRICE, "ETH/USD");
        pythInteractions.createPriceFeed(address(networkConfig.pythContract), BTC_USD_PRICE_FEED, BTC_PRICE, "BTC/USD");
    }
}
