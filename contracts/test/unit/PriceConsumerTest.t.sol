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
        BaseTest.setUpBaseTest();

        (dscEngineContract, networkConfig) = new DSCEngineDeploy().deploy(msg.sender, BaseTest.networkConfig);
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

    ////////////////////////////
    //        GET PRICE       //
    ////////////////////////////
    function test__success_getPriceOfEachCollateralToken() public view {
        address[] memory collateralTokens = BaseTest.networkConfig.collateralTokens;

        for (uint256 i = 0; i < collateralTokens.length; i++) {
            uint256 price = dscEngineContract.getPrice(collateralTokens[i]);

            console2.log("Price of Collateral Token:", price / 1e18);

            vm.assertGt(price, 0);
        }
    }

    function test__success_getUsdValue() public view localNetworkOnly {
        address collateralToken = BaseTest.networkConfig.collateralTokens[0];
        uint256 amount = 1e18;

        uint256 price = dscEngineContract.getPrice(collateralToken);

        uint256 expectedUsdValue = amount * (price / PRICE_PRECISSION);

        uint256 actualUsdValue = dscEngineContract.getUsdValue(collateralToken, amount);

        vm.assertEq(actualUsdValue, expectedUsdValue);
    }

    function test__success_getTokenAmountFromUsd() public view localNetworkOnly {
        address collateralToken = BaseTest.networkConfig.collateralTokens[0];
        uint256 usdAmount = 1e18;

        uint256 price = dscEngineContract.getPrice(collateralToken);

        uint256 expectedTokenAmount = (usdAmount * PRICE_PRECISSION) / price;

        uint256 actualTokenAmount = dscEngineContract.getTokenAmountFromUsd(collateralToken, usdAmount);

        vm.assertEq(actualTokenAmount, expectedTokenAmount);
    }

    function test__success_tokenPriceChangeAfterPriceChange() public localNetworkOnly {
        address collateralToken = BaseTest.networkConfig.collateralTokens[0];

        uint256 price = dscEngineContract.getPrice(collateralToken);

        helper_updatePriceFeed(
            address(networkConfig.pythContract), networkConfig.priceFeeds[0], ETH_PRICE_UPDATED, "Crypto.WETH/BTC"
        );

        uint256 priceAfterPriceChange = dscEngineContract.getPrice(collateralToken);

        vm.assertNotEq(price, priceAfterPriceChange);
    }

    function test__success_getUsdValueAfterPriceChange() public localNetworkOnly {
        address collateralToken = BaseTest.networkConfig.collateralTokens[0];
        uint256 amount = 1e18;

        uint256 price = dscEngineContract.getPrice(collateralToken);

        uint256 expectedUsdValue = amount * (price / PRICE_PRECISSION);

        uint256 actualUsdValue = dscEngineContract.getUsdValue(collateralToken, amount);

        vm.assertEq(actualUsdValue, expectedUsdValue);

        helper_updatePriceFeed(
            address(networkConfig.pythContract), networkConfig.priceFeeds[0], ETH_PRICE_UPDATED, "Crypto.WETH/BTC"
        );

        uint256 priceAfterChange = dscEngineContract.getPrice(collateralToken);

        vm.assertNotEq(price, priceAfterChange);

        uint256 expectedUsdValueAfterPriceChange = amount * (priceAfterChange / PRICE_PRECISSION);

        uint256 actualUsdValueAfterPriceChange = dscEngineContract.getUsdValue(collateralToken, amount);

        vm.assertEq(actualUsdValueAfterPriceChange, expectedUsdValueAfterPriceChange);
    }

    function test__success_getTokenAmountFromUsdAfterPriceChange() public localNetworkOnly {
        address collateralToken = BaseTest.networkConfig.collateralTokens[0];
        uint256 usdAmount = 1e18;

        uint256 price = dscEngineContract.getPrice(collateralToken);

        helper_updatePriceFeed(
            address(networkConfig.pythContract), networkConfig.priceFeeds[0], ETH_PRICE_UPDATED, "Crypto.WETH/BTC"
        );

        uint256 priceAfterChange = dscEngineContract.getPrice(collateralToken);

        vm.assertNotEq(price, priceAfterChange);

        uint256 expectedTokenAmount = (usdAmount * PRICE_PRECISSION) / priceAfterChange;

        uint256 actualTokenAmount = dscEngineContract.getTokenAmountFromUsd(collateralToken, usdAmount);

        vm.assertEq(actualTokenAmount, expectedTokenAmount);
    }
}
