// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {DSCEngine} from "../src/DSCEngine.sol";
import {DSCEngineDeploy} from "../script/DSCEngineDeploy.s.sol";

contract PriceConsumerTest is Test {
    DSCEngine dscEngineContract;

    function setUp() public {
        dscEngineContract = new DSCEngineDeploy().deploy(msg.sender);
    }

    function test__console() public pure {
        console2.log("Hello");
    }
}
