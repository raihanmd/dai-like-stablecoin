// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

abstract contract Constants {
    address public constant FOUNDRY_DEFAULT_SENDER =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    uint256 public constant LISK_SEPOLIA_CHAIN_ID = 4202;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}
