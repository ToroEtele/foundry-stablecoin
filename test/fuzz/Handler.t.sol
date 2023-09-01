// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

import {DecentralizedStableCoin} from "../../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../../src/DSCEngine.sol";

contract Handler is Test {
    DecentralizedStableCoin public dsc;
    DSCEngine public dsce;

    constructor(DSCEngine _dsce, DecentralizedStableCoin _dsc) {
        dsce = _dsce;
        dsc = _dsc;
    }

    // Call redeemCollateral only when there is collateral

    function depositCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) public {}
}
