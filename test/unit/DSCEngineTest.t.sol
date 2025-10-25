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
        BaseTest.setupUser(2);
        BaseTest.initiateBalanceUser(INITIAL_BALANCE);
        BaseTest.initiateCollateralBalance(INITIAL_BALANCE);

        (dscEngineContract, networkConfig) = new DSCEngineDeploy().deploy(msg.sender, BaseTest.networkConfig);
    }

    /////////////////////////////////////////
    //               HELPER                //
    /////////////////////////////////////////
    function helper_collateralApprove(address user, address collateralToken, uint256 amount) public {
        vm.prank(user);
        MockERC20(collateralToken).approve(address(dscEngineContract), amount);
    }

    function helper_dscApprove(address user, uint256 amount) public {
        vm.prank(user);
        MockERC20(networkConfig.dscContract).approve(address(dscEngineContract), amount);
    }

    function helper_deposit(address user, address collateralToken, uint256 amount) public {
        vm.prank(user);
        dscEngineContract.depositCollateral(collateralToken, amount);
    }

    /////////////////////////////////////////
    //            CONFIG RELATED           //
    /////////////////////////////////////////
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
                helper_collateralApprove(users[i], collateralTokens[j], AMOUNT_TO_DEPOSIT);

                vm.startPrank(users[i]);
                vm.expectEmit(true, true, false, true, address(dscEngineContract));
                emit CollateralDeposited(users[i], collateralTokens[j], AMOUNT_TO_DEPOSIT);
                vm.stopPrank();

                helper_deposit(users[i], collateralTokens[j], AMOUNT_TO_DEPOSIT);
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
    //         WITHDRAW COLLATERAL         //
    /////////////////////////////////////////
    function test__success_withdrawCollateral() public {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;
        uint256 collateralToBeWithdraw = AMOUNT_TO_DEPOSIT / 2;

        helper_collateralApprove(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);
        helper_deposit(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);

        vm.prank(users[0]);
        dscEngineContract.withdrawCollateral(collateralTokens[0], collateralToBeWithdraw);
    }

    function test_error_userCantWithdrawNotSupportedCollateral() public {
        /**
         * @notice Contract checking address contract, thus wichis address same as any address (e.g user)
         */
        address fakeCollateral = makeAddr("fakeCollateral");

        vm.prank(users[0]);
        vm.expectRevert(DSCEngine__CollateralTokenNotSupported.selector);
        dscEngineContract.withdrawCollateral(fakeCollateral, AMOUNT_TO_DEPOSIT);
    }

    function test_error_userCantWithdrawWithZeroAmount() public {
        vm.prank(users[0]);
        vm.expectRevert(DSCEngine__AmountShouldBeMoreThanZero.selector);
        dscEngineContract.withdrawCollateral(networkConfig.collateralTokens[0], 0);
    }

    /////////////////////////////////////////
    //              MINT DSC               //
    /////////////////////////////////////////
    function test__success_mintDSCAfterDepositCollateral() public {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;
        uint256 dscToBeMinted = AMOUNT_TO_DEPOSIT / 2;

        helper_collateralApprove(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);
        helper_deposit(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);

        vm.prank(users[0]);
        dscEngineContract.mintDsc(dscToBeMinted);

        (uint256 dscMinted,) = dscEngineContract.getAccountInformation(users[0]);

        vm.assertEq(dscMinted, dscToBeMinted);
    }

    function test_error_userCantMintDSCWithZeroAmount() public {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;

        helper_collateralApprove(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);
        helper_deposit(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);

        vm.prank(users[0]);
        vm.expectRevert(DSCEngine__AmountShouldBeMoreThanZero.selector);
        dscEngineContract.mintDsc(0);
    }

    /////////////////////////////////////////
    //              BURN DSC               //
    /////////////////////////////////////////
    function test__success_burnDSCAfterDepositCollateralAndMintDSC() public {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;
        uint256 dscToBeMinted = AMOUNT_TO_DEPOSIT / 2;
        uint256 dscToBeBurned = dscToBeMinted / 2;

        helper_collateralApprove(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);
        helper_deposit(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);

        vm.prank(users[0]);
        dscEngineContract.mintDsc(dscToBeMinted);

        (uint256 dscMintedFirstTime,) = dscEngineContract.getAccountInformation(users[0]);

        helper_dscApprove(users[0], dscToBeBurned);

        vm.prank(users[0]);
        dscEngineContract.burnDsc(dscToBeBurned);

        (uint256 dscAmountAfterBurn,) = dscEngineContract.getAccountInformation(users[0]);

        vm.assertEq(dscAmountAfterBurn, dscMintedFirstTime - dscToBeBurned);
    }

    function test__failed_burnDSCFailedIfNotEnoughAllowance() public {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;
        uint256 dscToBeMinted = AMOUNT_TO_DEPOSIT / 2;
        uint256 dscToBeBurned = dscToBeMinted / 2;

        helper_collateralApprove(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);
        helper_deposit(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);

        vm.prank(users[0]);
        dscEngineContract.mintDsc(dscToBeMinted);

        vm.expectRevert();
        vm.prank(users[0]);
        dscEngineContract.burnDsc(dscToBeBurned);
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
                helper_collateralApprove(users[i], collateralTokens[j], AMOUNT_TO_DEPOSIT);

                helper_deposit(users[i], collateralTokens[j], AMOUNT_TO_DEPOSIT);
                // deposit 0.5 token
                // ETH 0.5 * 4000 = 2000 USD
                // BTC 0.5 * 100000 = 50000 USD
                // TOTAL = 52000 USD

                (, uint256 tempCollateralValue) = dscEngineContract.getAccountInformation(users[i]);

                collateralValue = tempCollateralValue;

                sumPriceCollateral += dscEngineContract.getPrice(collateralTokens[j]);
                // 104000 USD
            }
            vm.assertEq(collateralValue, (AMOUNT_TO_DEPOSIT * sumPriceCollateral) / PRICE_PRECISSION);
        }
    }

    /////////////////////////////////////////
    //          GET HEALTH FACTOR          //
    /////////////////////////////////////////
    function test__success_shouldCorrectCalculatingHealthFactor() public {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;
        uint256 dscToBeMinted = AMOUNT_TO_DEPOSIT / 2;

        // deposit: 0.5 ETH, $2_000 e18
        helper_collateralApprove(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);
        helper_deposit(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);

        vm.prank(users[0]);
        dscEngineContract.mintDsc(dscToBeMinted);

        uint256 collateralValue = dscEngineContract.getCollateralValue(users[0]);

        uint256 healthFactor = dscEngineContract.getHealthFactor(users[0]);
        vm.assertEq(
            healthFactor,
            collateralValue * LIQUIDATION_THRESHOLD / LIQUIDATION_PRECISSION * PRICE_PRECISSION / dscToBeMinted
        );
    }
}
