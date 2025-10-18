// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {DSCEngine} from "../../src/DSCEngine.sol";
import {BaseTest} from "../BaseTest.t.sol";

import {DSCEngineDeploy} from "../../script/DSCEngineDeploy.s.sol";

contract DSCEngineTest is BaseTest {
    DSCEngine dscEngineContract;

    function setUp() public {
        setUpBaseTest();

        dscEngineContract = new DSCEngineDeploy().deploy(msg.sender, networkConfig);
    }

    function test__shouldGetCollateralTokens() public view {
        address[] memory collateralTokens = dscEngineContract.getCollateralTokens();
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            console2.log("Collateral Token:", collateralTokens[i]);
        }
    }
}
