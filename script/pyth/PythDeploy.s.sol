// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {MockPyth} from "@pythnetwork/pyth-sdk-solidity/MockPyth.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {Script} from "forge-std/Script.sol";

contract PythDeploy is Script {
    IPyth pyth;

    function run() public {
        deploy(msg.sender);
    }

    function deploy(address _deployer) public returns (IPyth) {
        vm.startBroadcast(_deployer);
        pyth = new MockPyth(60, 1);
        vm.stopBroadcast();

        return pyth;
    }
}
