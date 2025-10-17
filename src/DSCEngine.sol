// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

/**
 * @title DSCEngine
 * @author raihanmd
 * @notice The core contract of the DSC.
 *
 * The system is controling that 1 token equal to $1 USD peg.
 *
 * Its similar to how DAI works, but with no governance, no fees, and just only backed by WETH and WBTC
 *
 * This DSC also should be `over collateralized`. the value of collateral should be higher than the value of DSC
 */
contract DSCEngine {
    error DSCEngine__CollateralTokenNotSupported();

    struct UserProfile {
        uint256 wethBalance;
        uint256 wbtcBalance;
        uint256 dscBalance;
        uint256 totalCollateral;
    }

    address[2] private s_collateralTokens;

    mapping(address => UserProfile) private s_userProfile;

    constructor(address _wethAddress, address _wbtcAddress) {
        s_collateralTokens[0] = _wethAddress;
        s_collateralTokens[1] = _wbtcAddress;
    }

    function depositCollateralAndMintDsc() external {}

    function depositCollateral(
        address _collateralToken,
        uint256 _amount
    ) external _collateralTokenShouldBeSupported(_collateralToken) {}

    function redeemDscAndWithdrawCollateral() external {}

    function redeemDsc() external {}

    function withdrawCollateral() external {}

    function mintDsc() external {}

    function burnDsc() external {}

    function luquidate() external {}

    function getHealthFactor() external view returns (uint256) {}

    modifier _collateralTokenShouldBeSupported(address _collateralToken) {
        address[2] memory collateralTokens = s_collateralTokens;

        for (uint256 i = 0; i < collateralTokens.length; i++) {
            if (collateralTokens[i] != _collateralToken) {
                revert DSCEngine__CollateralTokenNotSupported();
            }
        }

        _;
    }
}
