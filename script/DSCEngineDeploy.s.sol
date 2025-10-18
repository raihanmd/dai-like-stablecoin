// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {Config} from "../script/config/Config.s.sol";

contract DSCEngineDeploy is Script {
    function run() public {
        deploy(msg.sender, new Config().getConfig());
    }

    function deploy(address _deployer, Config.NetworkConfig memory networkConfig)
        public
        returns (DSCEngine dscEngine)
    {
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
