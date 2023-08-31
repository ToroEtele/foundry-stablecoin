// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title Decentralized Stable Coin
 * @author Toró Etele
 * Collateral: exogenus (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stablity: Pegged to USD
 *
 * This contract is the ERC-20 implementation of the Decentralized Stable Coin. Should be governed by DSCEngine contract
 *
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    error DecentralizedStableCoin__AmountMustBeMoreThanZero();
    error DecentralizedStableCoin__BurnAmountExceedsBalance();
    error DecentralizedStableCoin__NotZeroAddress();

    constructor() ERC20("Decentralized Stable Coin", "DSC") {
        // _mint(msg.sender, 1000000000000000000000000000);
    }

    /*
     * @dev: This function overrides the ERC20Burnable burn function, before calling the original function,
     * checks if amount is greather than zero & greather than senders balance.
     * @param _amount: amount of DSC to be burned
     */
    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin__AmountMustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    /*
     * @dev: This function overrides the ERC20 mint function, before calling the original function,
     * checks if the address where the tokens are minted is not zero address & amount is greather than zero.
     * @param _to: address where the tokens are minted
     * @param _amount: amount of DSC to be minted
     */
    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert DecentralizedStableCoin__AmountMustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
