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

    function helper_mintDsc(address user, uint256 amount) public {
        vm.prank(user);
        dscEngineContract.mintDsc(amount);
    }

    function helper_burnDsc(address user, uint256 amount) public {
        vm.prank(user);
        dscEngineContract.burnDsc(amount);
    }

    function helper_withdrawCollateral(address user, address collateralToken, uint256 amount) public {
        vm.prank(user);
        dscEngineContract.withdrawCollateral(collateralToken, amount);
    }

    function helper_liquidate(address liquidator, address user, address collateralToken, uint256 amount) public {
        vm.prank(liquidator);
        dscEngineContract.liquidate(collateralToken, user, amount);
    }

    function helper_getAccountInformation(address user)
        public
        view
        returns (uint256 dscBalance, uint256 collateralValue)
    {
        (dscBalance, collateralValue) = dscEngineContract.getAccountInformation(user);
    }

    function helper_getUsdValue(address collateralToken, uint256 amount) public view returns (uint256) {
        return dscEngineContract.getUsdValue(collateralToken, amount);
    }

    function helper_getTokenAmountFromUsd(address collateralToken, uint256 usdAmount) public view returns (uint256) {
        return dscEngineContract.getTokenAmountFromUsd(collateralToken, usdAmount);
    }

    function helper_updatePriceFeed(address pythAddress, bytes32 priceFeedId, int64 price, string memory pair) public {
        vm.warp(block.timestamp + 10);
        vm.roll(block.number + 1);

        pythInteractions.updatePriceFeed(pythAddress, priceFeedId, price, pair);
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

    function test__error_constructorMissmatchArrayLength() public {
        address[] memory collateralTokens = new address[](2);
        bytes32[] memory priceFeeds = new bytes32[](1);
        uint256 pythMaxAge = 1;

        vm.expectRevert(DSCEngine.DSCEngine__ConstructorMissmatchArrayLength.selector);
        new DSCEngine(address(0), address(0), collateralTokens, priceFeeds, pythMaxAge);
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
                emit DSCEngine.CollateralDeposited(users[i], collateralTokens[j], AMOUNT_TO_DEPOSIT);
                vm.stopPrank();

                helper_deposit(users[i], collateralTokens[j], AMOUNT_TO_DEPOSIT);
            }
        }
    }

    function test__error_userCantDepositNotSupportedCollateral() public {
        /**
         * @notice Contract checking address contract, thus wichis address same as any address (e.g user)
         */
        address fakeCollateral = makeAddr("fakeCollateral");

        vm.prank(users[0]);
        vm.expectRevert(DSCEngine.DSCEngine__CollateralTokenNotSupported.selector);
        dscEngineContract.depositCollateral(fakeCollateral, AMOUNT_TO_DEPOSIT);
    }

    function test__error_userCantDepositWithZeroAmount() public {
        vm.prank(users[0]);
        vm.expectRevert(DSCEngine.DSCEngine__AmountShouldBeMoreThanZero.selector);
        dscEngineContract.depositCollateral(networkConfig.collateralTokens[0], 0);
    }

    function test__error_userCantDepositIfNotEnoughAllowance() public {
        vm.prank(users[0]);
        vm.expectRevert(DSCEngine.DSCEngine__AllowanceExceedsBalance.selector);
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

    function test__error_userCantWithdrawNotSupportedCollateral() public {
        /**
         * @notice Contract checking address contract, thus wichis address same as any address (e.g user)
         */
        address fakeCollateral = makeAddr("fakeCollateral");

        vm.prank(users[0]);
        vm.expectRevert(DSCEngine.DSCEngine__CollateralTokenNotSupported.selector);
        dscEngineContract.withdrawCollateral(fakeCollateral, AMOUNT_TO_DEPOSIT);
    }

    function test__error_userCantWithdrawWithZeroAmount() public {
        vm.prank(users[0]);
        vm.expectRevert(DSCEngine.DSCEngine__AmountShouldBeMoreThanZero.selector);
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

    function test__error_userCantMintDSCWithZeroAmount() public {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;

        helper_collateralApprove(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);
        helper_deposit(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);

        vm.prank(users[0]);
        vm.expectRevert(DSCEngine.DSCEngine__AmountShouldBeMoreThanZero.selector);
        dscEngineContract.mintDsc(0);
    }

    function test__error_userCantMintDSCIfBreaksHealthFactor() public {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;

        helper_collateralApprove(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);
        helper_deposit(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);

        uint256 usdValue = helper_getUsdValue(collateralTokens[0], AMOUNT_TO_DEPOSIT);

        vm.prank(users[0]);
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorIsTooLow.selector);
        dscEngineContract.mintDsc(usdValue);
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

    function test__failed_cantBurnWithZeroAmount() public {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;

        helper_collateralApprove(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);
        helper_deposit(users[0], collateralTokens[0], AMOUNT_TO_DEPOSIT);

        vm.prank(users[0]);
        vm.expectRevert(DSCEngine.DSCEngine__AmountShouldBeMoreThanZero.selector);
        dscEngineContract.mintDsc(0);
    }

    /////////////////////////////////////////
    //          DEPOSIT AND MINT           //
    /////////////////////////////////////////
    function test__success_userShouldCanDepositAndMintAndTriggerEvent() public {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;
        address collateralToken = collateralTokens[0];
        uint256 dscToMint = helper_getUsdValue(collateralToken, AMOUNT_TO_DEPOSIT / 3);

        helper_collateralApprove(users[0], collateralToken, AMOUNT_TO_DEPOSIT);

        vm.expectEmit(true, true, false, true, address(dscEngineContract));
        emit DSCEngine.CollateralDeposited(users[0], collateralToken, AMOUNT_TO_DEPOSIT);

        vm.prank(users[0]);
        dscEngineContract.depositCollateralAndMintDsc(collateralToken, AMOUNT_TO_DEPOSIT, dscToMint);

        (uint256 userDscMinted, uint256 userCollateralValue) = dscEngineContract.getAccountInformation(users[0]);
        uint256 expectedCollateralValue = helper_getUsdValue(collateralToken, AMOUNT_TO_DEPOSIT);

        vm.assertEq(userDscMinted, dscToMint, "DSC minted amount should match");
        vm.assertEq(userCollateralValue, expectedCollateralValue, "Collateral value should match");
    }

    /////////////////////////////////////////
    //  BURN DSC AND WITHDRAW COLLATERAN   //
    /////////////////////////////////////////
    function test__success_userShouldCanBurnDSCAndWithdrawCollateral() public {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;
        address collateralToken = collateralTokens[0];
        uint256 dscToMint = helper_getUsdValue(collateralToken, AMOUNT_TO_DEPOSIT / 3);

        helper_collateralApprove(users[0], collateralToken, AMOUNT_TO_DEPOSIT);

        vm.expectEmit(true, true, false, true, address(dscEngineContract));
        emit DSCEngine.CollateralDeposited(users[0], collateralToken, AMOUNT_TO_DEPOSIT);

        vm.prank(users[0]);
        dscEngineContract.depositCollateralAndMintDsc(collateralToken, AMOUNT_TO_DEPOSIT, dscToMint);

        (uint256 userDscMinted, uint256 userCollateralValue) = dscEngineContract.getAccountInformation(users[0]);
        uint256 expectedCollateralValue = helper_getUsdValue(collateralToken, AMOUNT_TO_DEPOSIT);

        vm.assertEq(userDscMinted, dscToMint, "DSC minted amount should match");
        vm.assertEq(userCollateralValue, expectedCollateralValue, "Collateral value should match");

        helper_dscApprove(users[0], dscToMint);

        vm.expectEmit(true, true, false, true, address(dscEngineContract));
        emit DSCEngine.CollateralWithdrawn(users[0], users[0], collateralToken, AMOUNT_TO_DEPOSIT);

        vm.prank(users[0]);
        dscEngineContract.burnDscAndWithdrawCollateral(collateralToken, AMOUNT_TO_DEPOSIT, dscToMint);

        (uint256 userDscMintedAfterBurn, uint256 userCollateralValueAfterBurn) =
            dscEngineContract.getAccountInformation(users[0]);

        vm.assertEq(userDscMintedAfterBurn, 0, "DSC minted amount should match");
        vm.assertEq(userCollateralValueAfterBurn, 0, "Collateral value should match");
    }

    /////////////////////////////////////////
    //           LIQUIDATE USER            //
    /////////////////////////////////////////
    function test__success_liquidateUser() public {
        address badActor = users[0];
        address liquidator = users[1];

        address collateralToken = BaseTest.networkConfig.collateralTokens[0];
        uint256 dscToBeMinted = helper_getUsdValue(collateralToken, AMOUNT_TO_DEPOSIT) / 2;

        // Bad Actor do the deposit and mint
        helper_collateralApprove(badActor, collateralToken, AMOUNT_TO_DEPOSIT);
        helper_deposit(badActor, collateralToken, AMOUNT_TO_DEPOSIT);

        helper_mintDsc(badActor, dscToBeMinted);

        // Liquidator do the deposit and mint
        helper_collateralApprove(liquidator, collateralToken, INITIAL_BALANCE);
        helper_deposit(liquidator, collateralToken, INITIAL_BALANCE);

        helper_mintDsc(liquidator, dscToBeMinted);

        uint256 collateralValue = dscEngineContract.getCollateralValue(users[0]);

        uint256 healthFactor = dscEngineContract.getHealthFactor(users[0]);

        vm.assertEq(
            healthFactor,
            collateralValue * LIQUIDATION_THRESHOLD / LIQUIDATION_PRECISSION * PRICE_PRECISSION / dscToBeMinted
        );

        helper_updatePriceFeed(
            address(networkConfig.pythContract), networkConfig.priceFeeds[0], ETH_PRICE_UPDATED, "ETH/USD"
        );

        helper_dscApprove(liquidator, dscToBeMinted);
        helper_liquidate(liquidator, badActor, collateralToken, dscToBeMinted);

        (uint256 badActorDscAmountAfterBurn,) = dscEngineContract.getAccountInformation(badActor);
        (uint256 liquidatorDscAmountAfterPriceUpdate,) = dscEngineContract.getAccountInformation(liquidator);

        vm.assertEq(badActorDscAmountAfterBurn, 0);

        vm.assertEq(liquidatorDscAmountAfterPriceUpdate, 0);
    }

    function test__error_liquidateUserCantWithAmountZero() public {
        address badActor = users[0];
        address liquidator = users[1];

        address collateralToken = BaseTest.networkConfig.collateralTokens[0];
        uint256 dscToBeMinted = helper_getUsdValue(collateralToken, AMOUNT_TO_DEPOSIT) / 2;

        // Bad Actor do the deposit and mint
        helper_collateralApprove(badActor, collateralToken, AMOUNT_TO_DEPOSIT);
        helper_deposit(badActor, collateralToken, AMOUNT_TO_DEPOSIT);

        helper_mintDsc(badActor, dscToBeMinted);

        // Liquidator do the deposit and mint
        helper_collateralApprove(liquidator, collateralToken, INITIAL_BALANCE);
        helper_deposit(liquidator, collateralToken, INITIAL_BALANCE);

        helper_mintDsc(liquidator, dscToBeMinted);

        uint256 collateralValue = dscEngineContract.getCollateralValue(users[0]);

        uint256 healthFactor = dscEngineContract.getHealthFactor(users[0]);

        vm.assertEq(
            healthFactor,
            collateralValue * LIQUIDATION_THRESHOLD / LIQUIDATION_PRECISSION * PRICE_PRECISSION / dscToBeMinted
        );

        helper_updatePriceFeed(
            address(networkConfig.pythContract), networkConfig.priceFeeds[0], ETH_PRICE_UPDATED, "ETH/USD"
        );

        helper_dscApprove(liquidator, dscToBeMinted);
        vm.expectRevert(DSCEngine.DSCEngine__AmountShouldBeMoreThanZero.selector);
        helper_liquidate(liquidator, badActor, collateralToken, 0);
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
