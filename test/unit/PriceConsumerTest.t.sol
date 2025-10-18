// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {DSCEngine} from "../../src/DSCEngine.sol";
import {DSCEngineDeploy} from "../../script/DSCEngineDeploy.s.sol";
import {BaseTest} from "../BaseTest.t.sol";

contract PriceConsumerTest is BaseTest {
    DSCEngine dscEngineContract;

    function setUp() public {
        setUpBaseTest();

        dscEngineContract = new DSCEngineDeploy().deploy(msg.sender, networkConfig);
    }

    function test__shouldSuccessGetPriceOfEachCollateralToken() public view {
        address[] memory collateralTokens = dscEngineContract.getCollateralTokens();
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            uint256 price = dscEngineContract.getPrice(collateralTokens[i]);

            console2.log("Price of Collateral Token:", price / 1e18);

            vm.assertGt(price, 0);
        }
    }
}
