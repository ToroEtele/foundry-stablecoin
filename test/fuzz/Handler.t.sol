// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {Test} from "forge-std/Test.sol";

import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";

contract Handler is Test {
    DecentralizedStableCoin public dsc;
    DSCEngine public engine;

    ERC20Mock public weth;
    ERC20Mock public wbtc;

    uint256 timesMintIsCalled = 0;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(DSCEngine _dsce, DecentralizedStableCoin _dsc) {
        engine = _dsce;
        dsc = _dsc;

        address[] memory collateralTokens = engine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    // Call redeemCollateral only when there is collateral

    function mintDsc(uint256 amountDsc) public {
        amountDsc = bound(amountDsc, 0, MAX_DEPOSIT_SIZE);
        vm.startPrank(msg.sender);
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine
            .getAccountInformation(msg.sender);
        int256 maxDscToMint = (int256(collateralValueInUsd) / 2) -
            int256(totalDscMinted);
        vm.assume(maxDscToMint >= 0);
        amountDsc = bound(amountDsc, 0, uint256(maxDscToMint));
        vm.assume(amountDsc != 0);
        dsc.mint(msg.sender, amountDsc);
        vm.stopPrank();
        timesMintIsCalled++;
    }

    function depositCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 0, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        //@dev: the user who wants to deposit must have enough collateral, and must approve for the engine to transfer
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(engine), amountCollateral);
        engine.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
    }

    function redeemCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = engine.getCollateralBalanceOfUser(
            address(collateral),
            msg.sender
        );
        amountCollateral = bound(amountCollateral, 0, maxCollateralToRedeem);
        vm.assume(amountCollateral != 0);
        // if (amountCollateral == 0) return;
        engine.redeemCollateral(address(collateral), amountCollateral);
    }

    // ! Helper Functions

    function _getCollateralFromSeed(
        uint256 collateralSeed
    ) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }
}
