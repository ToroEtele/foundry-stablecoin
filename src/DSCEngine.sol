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
contract DSCEngine {
    function depositCollateralAndMintDsc() external {}

    function redeemCollateralForDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}
}
