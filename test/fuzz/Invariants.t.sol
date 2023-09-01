// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// 1. Total supply of DSC should be less than the total value of collateral
// 2. Getter view functions should never revert

import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";

import {DecentralizedStableCoin} from "../../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {DeployDSC} from "../../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../../src/DSCEngine.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantTest is StdInvariant, Test {
    DecentralizedStableCoin public dsc;
    HelperConfig public helperConfig;
    DSCEngine public dsce;
    DeployDSC deployer;
    Handler handler;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dsce, helperConfig) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, ) = helperConfig
            .activeNetworkConfig();
        handler = new Handler(dsce, dsc);
        targetContract(address(handler));
    }

    /**
     * @notice get the all collateral in the protocol, than compare it to the total debt
     */
    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 wethDeposted = ERC20Mock(weth).balanceOf(address(dsce));
        uint256 wbtcDeposited = ERC20Mock(wbtc).balanceOf(address(dsce));

        uint256 wethValue = dsce.getUsdValue(weth, wethDeposted);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, wbtcDeposited);

        assert(wethValue + wbtcValue >= totalSupply);
    }
}
