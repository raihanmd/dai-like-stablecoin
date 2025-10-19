// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {DSCEngine} from "../../src/DSCEngine.sol";
import {MockERC20} from "../../src/mock/MockERC20.sol";
import {BaseTest} from "../BaseTest.t.sol";

import {DSCEngineDeploy} from "../../script/DSCEngineDeploy.s.sol";

/**
 * @notice BaseTest provide `networkConfig`
 */
contract DSCEngineTest is BaseTest {
    error DSCEngine__ConstructorMissmatchArrayLength();

    error DSCEngine__CollateralTokenNotSupported();
    error DSCEngine__AmountShouldBeMoreThanZero();
    error DSCEngine__AllowanceExceedsBalance();
    error DSCEngine__TransferFailed();
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorIsTooLow();

    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    DSCEngine dscEngineContract;

    uint256 constant INITIAL_BALANCE = 1e18;
    uint256 constant AMOUNT_TO_DEPOSIT = 0.5e18;

    function setUp() public {
        BaseTest.setUpBaseTest();
        BaseTest.setupUser(5);
        BaseTest.initiateBalanceUser(INITIAL_BALANCE);
        BaseTest.initiateCollateralBalance(INITIAL_BALANCE);

        dscEngineContract = new DSCEngineDeploy().deploy(msg.sender, BaseTest.networkConfig);
    }

    function test__success_balanceInCollateralShouldSameAsInitialize() public view BaseTest.localNetworkOnly() {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;

        for (uint256 i = 0; i < totalUsers; i++) {
            for (uint256 j = 0; j < collateralTokens.length; j++) {
                uint256 balance = MockERC20(networkConfig.collateralTokens[j]).balanceOf(users[i]);

                vm.assertEq(balance, INITIAL_BALANCE);
            }
        }
    }

    /////////////////////////////////////////
    //              DEPOSIT                //
    /////////////////////////////////////////
    function test__success_userShouldCanDepositAndTriggerEvent() public {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;

        for (uint256 i = 0; i < totalUsers; i++) {
            for (uint256 j = 0; j < collateralTokens.length; j++) {
                vm.startPrank(users[i]);
                MockERC20(networkConfig.collateralTokens[j]).approve(address(dscEngineContract), AMOUNT_TO_DEPOSIT);

                vm.expectEmit(true, true, false, true, address(dscEngineContract));
                emit CollateralDeposited(users[i], collateralTokens[j], AMOUNT_TO_DEPOSIT);

                dscEngineContract.depositCollateral(collateralTokens[j], AMOUNT_TO_DEPOSIT);
                vm.stopPrank();
            }
        }
    }

    function test_error_userCantDepositNotSupportedCollateral() public {
        /**
         * @notice Contract checking address contract, thus wichis address same as any address (e.g user)
         */
        address fakeCollateral = makeAddr("fakeCollateral");

        vm.prank(users[0]);
        vm.expectRevert(DSCEngine__CollateralTokenNotSupported.selector);
        dscEngineContract.depositCollateral(fakeCollateral, AMOUNT_TO_DEPOSIT);
    }

    function test_error_userCantDepositWithZeroAmount() public {
        vm.prank(users[0]);
        vm.expectRevert(DSCEngine__AmountShouldBeMoreThanZero.selector);
        dscEngineContract.depositCollateral(networkConfig.collateralTokens[0], 0);
    }

    function test_error_userCantDepositIfNotEnoughAllowance() public {
        vm.prank(users[0]);
        vm.expectRevert(DSCEngine__AllowanceExceedsBalance.selector);
        dscEngineContract.depositCollateral(networkConfig.collateralTokens[0], AMOUNT_TO_DEPOSIT);
    }

    /////////////////////////////////////////
    //       GET ACCOUNT INFORMATION       //
    /////////////////////////////////////////
    function test__success_shouldCorrectCalculatingTotalCollateralValue() public {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;

        for (uint256 i = 0; i < totalUsers; i++) {
            uint256 collateralValue;
            uint256 sumPriceCollateral;

            for (uint256 j = 0; j < collateralTokens.length; j++) {
                vm.startPrank(users[i]);
                MockERC20(networkConfig.collateralTokens[j]).approve(address(dscEngineContract), AMOUNT_TO_DEPOSIT);

                dscEngineContract.depositCollateral(collateralTokens[j], AMOUNT_TO_DEPOSIT);
                // deposit 0.5 token
                // ETH 0.5 * 4000 = 2000 USD
                // BTC 0.5 * 100000 = 50000 USD
                // TOTAL = 52000 USD

                vm.stopPrank();

                (, uint256 tempCollateralValue) = dscEngineContract.getAccountInformation(users[i]);

                collateralValue = tempCollateralValue;

                sumPriceCollateral += dscEngineContract.getPrice(collateralTokens[j]) / 1e18;
                // 104000 USD
            }
            vm.assertEq(collateralValue, AMOUNT_TO_DEPOSIT * sumPriceCollateral);
        }
    }
}
