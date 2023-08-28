// SPDX-License-Identifier: UNLICENSED

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.18;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 * @title DSCEngine
 * @author Toró Etele
 * Collateral: exogenus (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stablity: Pegged to USD
 *
 * This system is designed to maintani the stability of the Decentralized Stable Coin, 1 token (DSC) = 1 USD.
 * Similar to DAI except here is no governance, fees and DSC is only backed by wETH & wBTC.
 *
 * @notice This contract is the core of the Decentralized Stable Coin system, it handles all the logic for
 * mining and redeeming DSC, as well as depositiong and withdrawing collateral.
 * @notice The system should be always over collaterized. At no point should the value of the collateral be less than the value of the DSC in circulation.
 */
contract DSCEngine is ReentrancyGuard {
    // ! Errors
    error DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenNotAllowed(address token);
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactorValue);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    // ! State Variables
    DecentralizedStableCoin private immutable i_dsc;

    // @dev Mapping of token address to price feed address
    mapping(address collateralToken => address priceFeed) private s_priceFeeds;
    /// @dev Amount of collateral deposited by user
    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_collateralDeposited;
    // @dev Amount of DSC minted by user
    mapping(address user => uint256 amount) private s_DSCMinted;
    // @dev List of collateral tokens.
    address[] private s_collateralTokens;

    // ! Events
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    // ! Modifiers
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    // @dev Checks if the token is allowed to be used as collateral.
    // If the mapping for the address was not set to the price feed address, it has the default zeroth address value.
    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotAllowed(token);
        }
        _;
    }

    // ! Functions

    /*
     * @ The constructor is responsible for initializing the state vaiables of the contract.
     * @param tokenAddresses: The addresses of the ERC20 tokens that are allowed to be used as collateral
     * @param priceFeedAddresses: The addresses of the Chainlink Price Feeds for the ERC20 tokens
     * @param dscAddress: The address of the DSC token
     * @dev If the length of the tokenAddresses and priceFeedAddresses arrays don't match, the constructor reverts. Each possible collateral token must have a price feed.
     */
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    // ! External Functions

    function depositCollateralAndMintDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function redeemCollateralForDsc() external {}

    /*
     * @param tokenCollateralAddress: ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] -= amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /*
     * @param amountDscToMint: The amount of DSC you want to mint
     * You must have enough collateral
     */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function redeemCollateral() external {}

    function getHealthFactor() external {}

    // ! Private & Internal View Functions

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    /*
    *  @param user: The address of the user
    *  @returns how close a user to liquidation is. 
    *  @dev Ratio of DSC minted to collateral deposited.
    *  @dev Below 1 means the user is undercollaterized.
    *  Users below 1 can get liquidated.
    */
    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);

    }

    function _revertIfHealthFactorIsBroken(address user) internal view {

    }

    // ! Public & External View Functions

    /*
    * @param user: The address of the user
    * @returns Total collatelar value in USD, deposited in possible collateral tokens for the user.
    * @dev We have to loop through all the collateral tokens for the user and get the value of each one.
    */
    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 index = 0; index < s_collateralTokens.length; index++) {
            address token = s_collateralTokens[index];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += _getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }
}
