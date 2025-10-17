// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {Config} from "../script";

contract DSCEngineDeploy is Script {
    DSCEngine dscEngineContract;
    Config.NetworkConfig networkConfig;

    function run() public {
        deploy(msg.sender);
    }

    function deploy(address _deployer) public {
        vm.startBroadcast(_deployer);
        networkConfig = new Config().getConfig();

        dscEngineContract = new DSCEngine(
            networkConfig.wethAddress,
            networkConfig.wbtcAddress
        );
        vm.stopBroadcast();
    }
}
