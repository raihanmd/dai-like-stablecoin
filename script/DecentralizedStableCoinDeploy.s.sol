// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";

import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";

contract DecentralizedStableCoinDeploy is Script {
    function run() public {
        deploy(msg.sender);
    }

    function deploy(address _deployer) public returns (DecentralizedStableCoin dsc) {
        vm.startBroadcast(_deployer);
        dsc = new DecentralizedStableCoin();
        vm.stopBroadcast();

        return dsc;
    }
}
