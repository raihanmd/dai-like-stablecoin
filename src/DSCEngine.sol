// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {PriceConsumer} from "./lib/PriceConsumer.sol";

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
contract DSCEngine is ReentrancyGuard {
    error DSCEngine__ConstructorMissmatchArrayLength();

    error DSCEngine__CollateralTokenNotSupported();
    error DSCEngine__AmountShouldBeMoreThanZero();
    error DSCEngine__AllowanceExceedsBalance();
    error DSCEngine__TransferFailed();
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorIsTooLow();

    uint256 immutable i_pythMaxAge;
    uint8 constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralized
    uint8 constant LIQUIDATION_PRECISSION = 100;
    uint8 constant MIN_HEALTH_FACTOR = 1;
    uint256 constant PRECISSION = 1e18;

    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    /**
     * @dev Mapping of collateral token to USD
     */
    mapping(address token => bytes32 priceFeed) private s_collateralTokenPriceFeed;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateranDeposited;
    mapping(address user => uint256 dscMinted) private s_dscMinted;

    address[] private s_collateralTokens;

    IPyth immutable i_pythContract;
    DecentralizedStableCoin immutable i_dscContract;

    //////////////////////////////////
    //          MODIFIERS           //
    //////////////////////////////////

    /**
     * @notice Check if the collateral token is supported
     * @param _collateralTokenAddress Address of the collateral token
     */
    modifier collateralTokenAddressShouldBeSupported(address _collateralTokenAddress) {
        if (s_collateralTokenPriceFeed[_collateralTokenAddress] == bytes32(0)) {
            revert DSCEngine__CollateralTokenNotSupported();
        }

        _;
    }

    /**
     * @notice Check if the amount is more than zero
     * @param _amount Amount of collateral token
     */
    modifier moreThanZero(uint256 _amount) {
        if (_amount == 0) revert DSCEngine__AmountShouldBeMoreThanZero();

        _;
    }

    modifier healthFactorCheck() {
        uint256 healthFactor = _healthFactor(msg.sender);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorIsTooLow();
        }
        _;
    }

    constructor(
        address _pythContract,
        address _dscAddress,
        address[] memory _colalteralTokens,
        bytes32[] memory _priceFeeds,
        uint256 _pythMaxAge
    ) {
        if (_colalteralTokens.length != _priceFeeds.length) {
            revert DSCEngine__ConstructorMissmatchArrayLength();
        }

        i_pythMaxAge = _pythMaxAge;

        i_pythContract = IPyth(_pythContract);
        i_dscContract = DecentralizedStableCoin(_dscAddress);

        s_collateralTokens = _colalteralTokens;

        for (uint256 i = 0; i < _colalteralTokens.length; i++) {
            s_collateralTokenPriceFeed[_colalteralTokens[i]] = _priceFeeds[i];
        }
    }

    //////////////////////////////////
    //      EXTERNAL FUNCTIONS      //
    //////////////////////////////////
    function depositCollateralAndMintDsc(address _collateralTokenAddress, uint256 _amount) external {
        depositCollateral(_collateralTokenAddress, _amount);
        mintDsc(_amount);
    }

    /**
     * @param _collateralTokenAddress Supported ERC20 token address (WETH and WBTC)
     * @param _amount Amount of collateral token
     *
     * This function will deposit collateral token to the contract
     */
    function depositCollateral(address _collateralTokenAddress, uint256 _amount)
        public
        collateralTokenAddressShouldBeSupported(_collateralTokenAddress)
        moreThanZero(_amount)
        nonReentrant
    {
        if (IERC20(_collateralTokenAddress).allowance(msg.sender, address(this)) < _amount) {
            revert DSCEngine__AllowanceExceedsBalance();
        }

        s_collateranDeposited[msg.sender][_collateralTokenAddress] += _amount;

        emit CollateralDeposited(msg.sender, _collateralTokenAddress, _amount);

        bool success = IERC20(_collateralTokenAddress).transferFrom(msg.sender, address(this), _amount);

        if (!success) revert DSCEngine__TransferFailed();
    }

    function redeemDscAndWithdrawCollateral() external {}

    function redeemDsc() external {}

    function withdrawCollateral() external {}

    /**
     * @param _amount Amount of DSC to mint
     * @notice should overcollateralized and above minimum of threshold
     */
    function mintDsc(uint256 _amount) public moreThanZero(_amount) healthFactorCheck {
        s_dscMinted[msg.sender] += _amount;

        bool minted = i_dscContract.mint(msg.sender, _amount);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc() external {}

    function liquidate() external {}

    //////////////////////////////////
    // PRIVATE & INTERNAL FUNCTIONS //
    /////////////////////////////////

    /**
     * @notice Return how close is user to a liquidation
     *
     * If user goes below 1, it can be liquidated
     * The liquidation threshold is 50%, by that means as an example if the collateral value is 100, the user can mint up to 50 DSC
     * and if below that the user can be liquidated
     */
    function _healthFactor(address _user) private view returns (uint256) {
        (uint256 dscBalance, uint256 collateralValue) = _getAccountInformation(_user);
        if (dscBalance == 0) return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValue * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISSION; // e.g $150 * 50 / 100 = 75

        // Good e.g 75 * 1e18 / 50 = 1.5e18
        // Bad e.g 75 * 1e18 / 100 = 0.75e18

        return (collateralAdjustedForThreshold * PRECISSION) / dscBalance;
    }

    /**
     * @notice Return the DSC balance and collateral value
     */
    function _getAccountInformation(address _user) private view returns (uint256 dscBalance, uint256 collateralValue) {
        dscBalance = s_dscMinted[_user];
        collateralValue = getCollateralValue(_user);
        return (dscBalance, collateralValue);
    }

    //////////////////////////////////
    //       PUBLIC FUNCTIONS       //
    //////////////////////////////////
    function getHealthFactor(address _user) public view returns (uint256) {
        return _healthFactor(_user);
    }

    function getCollateralValue(address _user) public view returns (uint256 totalCollateralValue) {
        address[] memory collateralTokens = s_collateralTokens;

        for (uint256 i = 0; i < collateralTokens.length; i++) {
            address token = collateralTokens[i];
            uint256 amount = s_collateranDeposited[_user][token];

            if (amount > 0) {
                uint256 price =
                    PriceConsumer.oracle_getPricePush(i_pythContract, s_collateralTokenPriceFeed[token], i_pythMaxAge);
                totalCollateralValue += (amount * price) / PriceConsumer.PRICE_PRECISION;
            }
        }
    }

    function getAccountInformation(address _user) public view returns (uint256 dscBalance, uint256 collateralValue) {
        return _getAccountInformation(_user);
    }

    function getPrice(address _collateralToken) public view returns (uint256) {
        return PriceConsumer.oracle_getPricePush(
            i_pythContract, s_collateralTokenPriceFeed[_collateralToken], i_pythMaxAge
        );
    }
}
