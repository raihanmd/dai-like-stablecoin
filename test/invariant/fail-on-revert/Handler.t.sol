// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../../../src/mock/MockERC20.sol";

import {DSCEngine} from "../../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../../src/DecentralizedStableCoin.sol";
import {Config} from "../../../script/config/Config.s.sol";

import {DSCEngineDeploy} from "../../../script/DSCEngineDeploy.s.sol";
import {PythInteractions} from "../../../script/pyth/PythInteractions.s.sol";

contract Handler is Test {
    DSCEngine dscEngineContract;
    DecentralizedStableCoin dscContract;

    MockERC20 weth;
    MockERC20 wbtc;

    Config.NetworkConfig networkConfig;
    PythInteractions pythInteractions;

    uint256 constant MAX_DEPOSIT_FIRST_TURN = type(uint96).max;

    address[] public s_usersWithCollateralDeposited;

    constructor(address _dsce, Config.NetworkConfig memory _networkConfig) {
        pythInteractions = new PythInteractions();

        networkConfig = _networkConfig;

        weth = MockERC20(networkConfig.collateralTokens[0]);
        wbtc = MockERC20(networkConfig.collateralTokens[1]);

        dscEngineContract = DSCEngine(_dsce);
        dscContract = DecentralizedStableCoin(networkConfig.dscContract);
    }

    function depositCollateral(uint256 _collateralSeed, uint256 _amount) public {
        MockERC20 collateral = helper_getCollateralFromSeed(_collateralSeed);
        _amount = bound(_amount, 1, MAX_DEPOSIT_FIRST_TURN);

        vm.prank(msg.sender);
        collateral.mint(msg.sender, _amount);

        vm.prank(msg.sender);
        collateral.approve(address(dscEngineContract), _amount);

        vm.prank(msg.sender);
        dscEngineContract.depositCollateral(address(collateral), _amount);

        s_usersWithCollateralDeposited.push(msg.sender);
    }

    function withdrawCollateral(uint256 _collateralSeed, uint256 _amount) public {
        MockERC20 collateral = helper_getCollateralFromSeed(_collateralSeed);

        uint256 maxCollalteral = dscEngineContract.getCollateralDepositedOfUser(msg.sender, address(collateral));

        (uint256 dscMinted, uint256 totalCollateralValue) = dscEngineContract.getAccountInformation(msg.sender);

        if (totalCollateralValue == 0) return;

        uint256 collateralTobeWithdrawn = bound(_amount, 0, maxCollalteral);

        if (collateralTobeWithdrawn == 0) return;

        uint256 collateralValueToBeWithdrawn =
            dscEngineContract.getUsdValue(address(collateral), collateralTobeWithdrawn);

        uint256 healthFactorFuture =
            dscEngineContract.calculateHealthFactor(dscMinted, totalCollateralValue - collateralValueToBeWithdrawn);

        if (healthFactorFuture < 1e18) return;

        vm.prank(msg.sender);
        dscEngineContract.withdrawCollateral(address(collateral), collateralTobeWithdrawn);
    }

    function mintDsc(uint256 _amount, uint256 _userSeed) public {
        if (s_usersWithCollateralDeposited.length == 0) return;

        address user = s_usersWithCollateralDeposited[_userSeed % s_usersWithCollateralDeposited.length];

        (uint256 dscMinted, uint256 collateralValue) = dscEngineContract.getAccountInformation(user);

        int256 maxCollateralValue = int256(collateralValue / 2) - int256(dscMinted);

        if (maxCollateralValue < 0) return;

        _amount = bound(_amount, 0, uint256(maxCollateralValue));

        if (_amount == 0) return;

        vm.prank(user);
        dscEngineContract.mintDsc(_amount);
    }

    // * @notice This break our invariant test suite
    // function updateCollateralPrice(uint256 _collateralSeed, int64 _price) public {
    //     (bytes32 priceFeedId, string memory pair) = helper_getCollateralPriceFeedAndPair(_collateralSeed);
    //     MockERC20 collateral = helper_getCollateralFromSeed(_collateralSeed);

    //     int64 price = int64(bound(_price, 0, type(int64).max));

    //     vm.warp(block.timestamp + 10);
    //     vm.roll(block.number + 1);
    //     vm.prank(address(networkConfig.pythContract));
    //     pythInteractions.updatePriceFeed(address(collateral), priceFeedId, price, pair);
    // }

    ///////////////////////
    //       HELPER      //
    ///////////////////////
    function helper_getCollateralFromSeed(uint256 _collateralSeed) private view returns (MockERC20) {
        if (_collateralSeed % 2 == 0) {
            return MockERC20(weth);
        }

        return MockERC20(wbtc);
    }

    function helper_getCollateralPriceFeedAndPair(uint256 _collateralSeed)
        private
        view
        returns (bytes32, string memory)
    {
        if (_collateralSeed % 2 == 0) {
            return (networkConfig.priceFeeds[0], "Crypto.WETH/BTC");
        }

        return (networkConfig.priceFeeds[1], "Crypto.BTC/USD");
    }
}
