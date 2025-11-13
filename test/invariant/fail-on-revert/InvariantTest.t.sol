// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {console2} from "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DSCEngine} from "../../../src/DSCEngine.sol";
import {BaseTest} from "../../BaseTest.t.sol";
import {Handler} from "./Handler.t.sol";

import {DSCEngineDeploy} from "../../../script/DSCEngineDeploy.s.sol";

//* 1. The total supply of DSC should always less than the total value of the collateral
//* 2. Getter function should always not revert

contract InvariantTest is BaseTest {
    DSCEngine dscEngineContract;
    Handler handler;

    uint256 constant INITIAL_BALANCE = 1e18;
    uint256 constant AMOUNT_TO_DEPOSIT = 0.5e18;

    function setUp() public {
        BaseTest.setUpBaseTest();
        BaseTest.setupUser(2);
        BaseTest.initiateBalanceUser(INITIAL_BALANCE);
        BaseTest.initiateCollateralBalance(INITIAL_BALANCE);

        (dscEngineContract, networkConfig) = new DSCEngineDeploy().deploy(msg.sender, BaseTest.networkConfig);

        handler = new Handler(address(dscEngineContract), networkConfig);

        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() external view {
        uint256 totalSupply = dscEngineContract.getTotalSupply();
        uint256 totalWethDeposited =
            IERC20(BaseTest.networkConfig.collateralTokens[0]).balanceOf(address(dscEngineContract));
        uint256 totalWbtcDeposited =
            IERC20(BaseTest.networkConfig.collateralTokens[1]).balanceOf(address(dscEngineContract));

        uint256 totalWethValue =
            dscEngineContract.getUsdValue(BaseTest.networkConfig.collateralTokens[0], totalWethDeposited);
        uint256 totalWbtcValue =
            dscEngineContract.getUsdValue(BaseTest.networkConfig.collateralTokens[1], totalWbtcDeposited);

        console2.log("totalWethValue", totalWethValue);
        console2.log("totalWbtcValue", totalWbtcValue);
        console2.log("totalSupply", totalSupply);

        vm.assertGe(totalWethValue + totalWbtcValue, totalSupply);
    }

    function invariant_getterWithNoArgsShouldNotRevert() external view {
        dscEngineContract.getPythAddress();

        dscEngineContract.getTotalSupply();

        dscEngineContract.getCollateralTokens();
    }
}
