// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {LiquidityManager} from "../../src/LiquidityManager.sol";
import {CometMainInterface} from "../../src/interfaces/IComet.sol";
import {CometExtInterface} from "../../src/interfaces/ICometExt.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityManagerTest is Test {
    LiquidityManager public supplyLiquidity;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    address owner = address(1);
    uint256 sepoliaFork;
    uint256 fork;
    string ETH_SEPOLIA_RPC_URL = vm.envString("ETH_SEPOLIA_RPC_URL");
    string AVAX_FUJI_RPC_URL = vm.envString("AVAX_FUJI_RPC_URL");
    string BASE_SEPOLIA_RPC_URL_2 = vm.envString("BASE_SEPOLIA_RPC_URL_2");

    function setUp() public {
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getBaseSepoliaConfig();
        fork = vm.createSelectFork(BASE_SEPOLIA_RPC_URL_2);
        vm.startPrank(owner);
        supplyLiquidity = new LiquidityManager(
            address(networkConfig.aavePool),
            address(networkConfig.compoundUsdc)
        );
        vm.stopPrank();
        deal(networkConfig.usdc, owner, 1000000000000);
    }

    function testSupplyUSDCOnAave() public {
        vm.startPrank(owner);
        IERC20(networkConfig.usdc).approve(address(supplyLiquidity), 69);
        supplyLiquidity.supplyLiquidityOnAave(networkConfig.usdc, 69);
        (uint256 totalCollateralBase, , , , , ) = supplyLiquidity
            .getAaveLiquidityStatus(owner);
        assertGt(totalCollateralBase, 0);
        assertEq(IERC20(networkConfig.aaveUsdc).balanceOf(address(owner)), 69);
        vm.stopPrank();
    }

    function testWithdrawUSDCFromAave() public {
        vm.startPrank(owner);
        IERC20(networkConfig.usdc).approve(address(supplyLiquidity), 69);
        supplyLiquidity.supplyLiquidityOnAave(networkConfig.usdc, 69);
        IERC20(networkConfig.aaveUsdc).approve(address(supplyLiquidity), 69);
        supplyLiquidity.withdrawLiquidityFromAave(
            networkConfig.usdc,
            networkConfig.aaveUsdc,
            69
        );
        (uint256 totalCollateralBase, , , , , ) = supplyLiquidity
            .getAaveLiquidityStatus(owner);
        assertEq(totalCollateralBase, 0);
        vm.stopPrank();
    }

    function testSupplyUSDCOnCompound() public {
        vm.startPrank(owner);
        IERC20(networkConfig.usdc).approve(address(supplyLiquidity), 69000000);
        supplyLiquidity.supplyLiquidityOnCompound(networkConfig.usdc, 69000000);
        assertGt(supplyLiquidity.getCompoundLiquidityStatus(owner), 0);
        vm.stopPrank();
    }

    function testWithdrawUSDCFromCompound() public {
        vm.startPrank(owner);
        IERC20(networkConfig.usdc).approve(address(supplyLiquidity), 69000000);
        supplyLiquidity.supplyLiquidityOnCompound(networkConfig.usdc, 69000000);
        CometExtInterface(networkConfig.compoundUsdc).allow(
            address(supplyLiquidity),
            true
        );
        supplyLiquidity.withdrawLiquidityFromCompound(networkConfig.usdc, 100);
        assertLt(supplyLiquidity.getCompoundLiquidityStatus(owner), 69000000);
    }
}
