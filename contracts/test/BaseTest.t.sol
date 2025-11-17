// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";

import {DSCEngineDeploy} from "../script/DSCEngineDeploy.s.sol";
import {Config} from "../script/config/Config.s.sol";
import {Constants} from "../script/config/Constants.s.sol";
import {PythDeploy} from "../script/pyth/PythDeploy.s.sol";
import {PythInteractions} from "../script/pyth/PythInteractions.s.sol";
import {DecentralizedStableCoinDeploy} from "../script/DecentralizedStableCoinDeploy.s.sol";

contract BaseTest is Test, Constants {
    uint256 constant PRICE_PRECISSION = 1e18;
    uint256 constant LIQUIDATION_THRESHOLD = 50;
    uint256 constant LIQUIDATION_PRECISSION = 100;

    PythInteractions pythInteractions;

    Config.NetworkConfig internal networkConfig;
    mapping(uint256 => address) users;
    uint256 internal totalUsers;

    function setUpBaseTest() internal {
        pythInteractions = new PythInteractions();
        networkConfig = new Config().getConfig();
    }

    function setupUser(uint256 _total) internal {
        totalUsers = _total;
        for (uint256 i = 0; i < _total; i++) {
            users[i] = makeAddr(string.concat("user", vm.toString(i)));
        }
    }

    function initiateBalanceUser(uint256 amount) internal {
        for (uint256 i = 0; i < totalUsers; i++) {
            vm.deal(users[i], amount);
        }
    }

    function initiateCollateralBalance(uint256 amount) internal {
        for (uint256 i = 0; i < totalUsers; i++) {
            for (uint256 j = 0; j < networkConfig.collateralTokens.length; j++) {
                MockERC20(networkConfig.collateralTokens[j]).mint(users[i], amount);
            }
        }
    }

    modifier localNetworkOnly() {
        if (block.chainid != LOCAL_CHAIN_ID) return;
        _;
    }
}
