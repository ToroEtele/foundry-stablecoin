// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {Test, console} from "forge-std/Test.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;

    DecentralizedStableCoin public dsc;
    HelperConfig public helperConfig;
    DSCEngine public dsce;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;
    uint256 public deployerKey;

    uint256 amountCollateral = 10 ether;
    uint256 amountToMint = 100 ether;
    address public user = address(1);

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant LIQUIDATION_THRESHOLD = 50;
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, helperConfig) = deployer.run();
        (
            ethUsdPriceFeed,
            btcUsdPriceFeed,
            weth,
            wbtc,
            deployerKey
        ) = helperConfig.activeNetworkConfig();

        ERC20Mock(weth).mint(user, STARTING_USER_BALANCE);
        ERC20Mock(wbtc).mint(user, STARTING_USER_BALANCE);
    }

    // ! Constructor Tests:
    address[] public tokenAddresses;
    address[] public feedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        feedAddresses.push(ethUsdPriceFeed);
        feedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(
            DSCEngine
                .DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch
                .selector
        );
        new DSCEngine(tokenAddresses, feedAddresses, address(dsc));
    }

    // ! Price Tests:
    function testGetTokenAmountFromUsd() public {
        // If we want $100 of WETH @ $2000/WETH, that would be 0.05 WETH
        uint256 tokenAmountInUsd = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 amountWeth = dsce.getTokenAmountFromUsd(weth, tokenAmountInUsd);
        assertEq(amountWeth, expectedWeth);
    }

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        // 15e18 ETH * $2000/ETH = $30,000e18
        uint256 expectedUsd = 30000e18;
        uint256 usdValue = dsce.getUsdValue(weth, ethAmount);
        assertEq(usdValue, expectedUsd);
    }

    // ! Deposit Collateral Tests:

    function testRevertsIfCollateralZero() public {
        vm.startPrank(user);
        //@dev - Approve the DSCEngine to spend the user's WETH
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock randToken = new ERC20Mock();
        randToken.mint(user, amountCollateral);
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                DSCEngine.DSCEngine__TokenNotAllowed.selector,
                address(randToken)
            )
        );
        dsce.depositCollateral(address(randToken), amountCollateral);
        vm.stopPrank();
    }

    modifier depositCollateral() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(weth, amountCollateral);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralWithoutMinting() public depositCollateral {
        uint256 userBalance = dsc.balanceOf(user);
        assertEq(userBalance, 0);
    }

    function testCanDepositCollateralAndGetAccountInfo()
        public
        depositCollateral
    {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce
            .getAccountInformation(user);
        uint256 expectedDepositedAmount = dsce.getTokenAmountFromUsd(
            weth,
            collateralValueInUsd
        );
        assertEq(totalDscMinted, 0);
        assertEq(expectedDepositedAmount, amountCollateral);
    }

    // ! Deposit collateral and mint DSC Tests:
    // ! Mint DSC Tests:
    // ! Burn DSC Tests:
    // ! Redeem collateral Tests:
    // ! Redeem collateral for DSCC Tests:
    // ! Health factor Tests:
    // ! Liquidation Tests:
    // ! View & Pure Function Tests
}
