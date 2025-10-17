// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {Config} from "../script/config/Config.s.sol";

contract DSCEngineDeploy is Script {
    Config.NetworkConfig networkConfig;

    function run() public {
        deploy(msg.sender);
    }

    function deploy(address _deployer) public returns (DSCEngine dscEngine) {
        networkConfig = new Config().getConfig();

        vm.startBroadcast(_deployer);
        dscEngine = new DSCEngine(
            networkConfig.pythContract,
            networkConfig.dscAddress,
            networkConfig.colateralTokens,
            networkConfig.priceFeeds
        );
        vm.stopBroadcast();

        return dscEngine;
    }
}
