// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {SupplyLiquidity} from "../../src/SupplyLiquidity.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SupplyLiquidityTest is Test {
    SupplyLiquidity public supplyLiquidity;
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
        supplyLiquidity = new SupplyLiquidity(address(networkConfig.aavePool));
        vm.stopPrank();
        deal(networkConfig.usdc, owner, 69);
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
}
