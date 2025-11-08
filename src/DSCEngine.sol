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
    error DSCEngine__HealthFactorIsFine();
    error DSCEngine__HealthNotImproved();

    uint256 immutable i_pythMaxAge;
    uint8 constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralized
    uint8 constant LIQUIDATION_PRECISSION = 100;
    uint8 constant LIQUIDATION_BONUS = 10;
    uint256 constant MIN_HEALTH_FACTOR = 1e18;
    uint256 constant PRECISSION = 1e18;

    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event CollateralWithdrawn(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount
    );

    /**
     * @dev Mapping of collateral token to USD
     */
    mapping(address token => bytes32 priceFeed) private s_collateralTokenPriceFeed;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
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

    /**
     * @param _collateralTokenAddress Supported ERC20 token address (WETH and WBTC)
     * @param _collateralTokenAddress Amount of collateral token
     * @param _dscAmount Amount of DSC
     *
     * This function combine depositCollateral and mintDsc function
     *
     * depositCollateral: deposit collateral token to the contract
     * mintDsc: will mint DSC with specified amount
     */
    function depositCollateralAndMintDsc(address _collateralTokenAddress, uint256 _collateralAmount, uint256 _dscAmount)
        external
    {
        depositCollateral(_collateralTokenAddress, _collateralAmount);
        mintDsc(_dscAmount);
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

        s_collateralDeposited[msg.sender][_collateralTokenAddress] += _amount;

        emit CollateralDeposited(msg.sender, _collateralTokenAddress, _amount);

        bool success = IERC20(_collateralTokenAddress).transferFrom(msg.sender, address(this), _amount);

        if (!success) revert DSCEngine__TransferFailed();
    }

    /**
     * @param _collateralTokenAddress The address of collateral token
     * @param _amountCollateral The amount of collateral token to withdraw
     * @param _amountDsc The amount of DSC to burn
     *
     * This function will withdraw collateral token with specified amount
     */
    function burnDscAndWithdrawCollateral(
        address _collateralTokenAddress,
        uint256 _amountCollateral,
        uint256 _amountDsc
    ) external {
        burnDsc(_amountDsc);
        withdrawCollateral(_collateralTokenAddress, _amountCollateral);
    }

    /**
     * @param _collateralTokenAddress The address of collateral token
     * @param _amount The amount of collateral token to withdraw
     *
     * This function will withdraw collateral token with specified amount
     * also check health factor
     */
    function withdrawCollateral(address _collateralTokenAddress, uint256 _amount)
        public
        collateralTokenAddressShouldBeSupported(_collateralTokenAddress)
        nonReentrant
    {
        _withdrawCollateral(msg.sender, msg.sender, _collateralTokenAddress, _amount);
        helper_healthFactorCheck(msg.sender);
    }

    /**
     * @param _amount Amount of DSC to mint
     * @notice should overcollateralized and above minimum of threshold
     */
    function mintDsc(uint256 _amount) public moreThanZero(_amount) {
        uint256 hfAfter = _healthFactorWithExtraDebt(msg.sender, _amount);
        if (hfAfter < MIN_HEALTH_FACTOR) revert DSCEngine__HealthFactorIsTooLow();
        s_dscMinted[msg.sender] += _amount;
        bool minted = i_dscContract.mint(msg.sender, _amount);
        if (!minted) revert DSCEngine__MintFailed();
    }

    /**
     * @param _amount The amount to be burn
     *
     * This founction will burn dsc amount with specified amount
     */
    function burnDsc(uint256 _amount) public nonReentrant {
        _burnDsc(msg.sender, msg.sender, _amount);
        helper_healthFactorCheck(msg.sender);
    }

    /**
     * @param _collateralTokenAddress The ERC20 collateral to liquidate
     * @param _user The user who has broken their health factor. Their health factor below MIN_HEALTH_FACTOR
     * @param _debtToCover The amount of DSC you want to burn to improve the users health factor
     * @notice You can partially liquidate liquidate a user
     * @notice You will get a liquidation bonus for taking the users funds
     * @notice This function working assumes the protocol will be roughly 200% overcollateralized in order for this to work.
     *
     * e.g if the user in the first place deposit $100 worth of ETH, and mint 50 DSC
     * and if the collateral value drop to $75, this user health factor is bad, so liquidator can liquidate this user by paying 50 DSC and get their colalteral value which is $75
     *
     * if someway the collateral value drop lets say to $20, you still need to pay 50 DSC and get collateral value worth of $20
     *
     * @notice A known bug would be if the protocol were 100% or less collateralized, then we wouldn;t be able to incentive the liquidator
     */
    function liquidate(address _collateralTokenAddress, address _user, uint256 _debtToCover)
        external
        moreThanZero(_debtToCover)
        nonReentrant
    {
        uint256 startingHealthFactor = _healthFactor(_user);
        if (startingHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorIsFine();
        }

        // Lets assume ETH price $4_000
        // Bad user $75 ETH -> 50 DSC
        // 50 DSC = 50 / 4000 = 0.0125 ETH
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(_collateralTokenAddress, _debtToCover);

        // Bonus = 0.0125 ETH * 10% = 0.00125 ETH
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS / LIQUIDATION_PRECISSION);

        // Total = 0.01375 ETH
        uint256 totalCollateralToWithdraw = tokenAmountFromDebtCovered + bonusCollateral;

        _withdrawCollateral(_user, msg.sender, _collateralTokenAddress, totalCollateralToWithdraw);

        s_dscMinted[msg.sender] -= _debtToCover;
        _burnDsc(_user, msg.sender, _debtToCover);

        uint256 endingHealthFactor = _healthFactor(_user);
        if (endingHealthFactor <= startingHealthFactor) revert DSCEngine__HealthNotImproved();

        helper_healthFactorCheck(msg.sender);
    }

    //////////////////////////////////
    // PRIVATE & INTERNAL FUNCTIONS //
    /////////////////////////////////

    /**
     * @notice Return how close is user to a liquidation
     *
     * If user goes below 1e18, it can be liquidated
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

    /**
     * @dev Low level internal function, dont call this function unless, the function calling it is checking for health factor
     * @dev And also make sure the function calling it is checking for reentrancy
     * @param _from User that will decreace the collateral
     * @param _to User receiver collateral token
     * @param _collateralTokenAddress Address of collateral token
     * @param _amount Amount of collateral
     */
    function _withdrawCollateral(address _from, address _to, address _collateralTokenAddress, uint256 _amount)
        private
        moreThanZero(_amount)
    {
        s_collateralDeposited[_from][_collateralTokenAddress] -= _amount;
        emit CollateralWithdrawn(_from, _to, _collateralTokenAddress, _amount);

        bool success = IERC20(_collateralTokenAddress).transfer(_to, _amount);
        if (!success) revert DSCEngine__TransferFailed();
    }

    /**
     * @dev Low level internal function, dont call this function unless, the function calling it is checking for health factor
     * @dev And also make sure the function calling it is checking for reentrancy
     * @param _onBehalfOf User that will decreace the DSC minted mapping
     * @param _dscFrom User that transfer their DSC to this contract
     * @param _amount Amount of DSC
     */
    function _burnDsc(address _onBehalfOf, address _dscFrom, uint256 _amount) private moreThanZero(_amount) {
        s_dscMinted[_onBehalfOf] -= _amount;
        bool success = i_dscContract.transferFrom(_dscFrom, address(this), _amount);

        if (!success) revert DSCEngine__TransferFailed();

        i_dscContract.burn(_amount);
    }

    function _healthFactorWithExtraDebt(address _user, uint256 _extraDsc) private view returns (uint256) {
        (uint256 dscBalance, uint256 collateralValue) = _getAccountInformation(_user);
        uint256 newDscBalance = dscBalance + _extraDsc;
        if (newDscBalance == 0) return type(uint256).max;
        uint256 collateralAdjusted = (collateralValue * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISSION;
        return (collateralAdjusted * PRECISSION) / newDscBalance;
    }

    //////////////////////////////////
    //       PUBLIC FUNCTIONS       //
    //////////////////////////////////

    /**
     * @param _user User address
     *
     * This function return user's health factor
     * The minimun threshold health factor is 1
     * by that mean, if health factor lower than 1, user is legitimate to liquidated
     */
    function getHealthFactor(address _user) public view returns (uint256) {
        return _healthFactor(_user);
    }

    /**
     * @param _user User address used extract their account information
     *
     * This function will return the value of collateral deposited in USD (no precission conversion needed)
     */
    function getCollateralValue(address _user) public view returns (uint256 totalCollateralValue) {
        address[] memory collateralTokens = s_collateralTokens;

        for (uint256 i = 0; i < collateralTokens.length; i++) {
            address token = collateralTokens[i];
            uint256 amount = s_collateralDeposited[_user][token];

            if (amount > 0) {
                uint256 price =
                    PriceConsumer.oracle_getPricePush(i_pythContract, s_collateralTokenPriceFeed[token], i_pythMaxAge);
                totalCollateralValue += (amount * price) / PriceConsumer.PRICE_PRECISION;
            }
        }
    }

    /**
     * @param _user User address used extract their account information
     *
     * This function will return the DSC balance and collateral value
     */
    function getAccountInformation(address _user) public view returns (uint256 dscBalance, uint256 collateralValue) {
        return _getAccountInformation(_user);
    }

    /**
     * @param _collateralToken Address of the collateral token
     *
     * This function will return the price of the collateral token
     */
    function getPrice(address _collateralToken) public view returns (uint256) {
        return PriceConsumer.oracle_getPricePush(
            i_pythContract, s_collateralTokenPriceFeed[_collateralToken], i_pythMaxAge
        );
    }

    function getTokenAmountFromUsd(address _collateralToken, uint256 _usdAmountInWei) public view returns (uint256) {
        uint256 price = getPrice(_collateralToken);

        // $1000e18 * 1e18 / $4000e18 = 0.25e18
        return (_usdAmountInWei * PRECISSION) / price;
    }

    function getUsdValue(address _collateralToken, uint256 _amount) public view returns (uint256) {
        uint256 price = getPrice(_collateralToken);
        return (_amount * price) / PRECISSION;
    }

    function getPythAddress() public view returns (address) {
        return address(i_pythContract);
    }

    //////////////////////////////////
    //       HELPER FUNCTIONS       //
    //////////////////////////////////
    function helper_healthFactorCheck(address _user) private view {
        uint256 healthFactor = _healthFactor(_user);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorIsTooLow();
        }
    }
}
