// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Vault} from "../../src/Vault.sol";
import {VaultFactory} from "../../src/VaultFactory.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultTest is Test {
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    address owner = address(1);
    address user = address(2);
    VaultFactory public vaultFactory;
    uint256 fork;
    string BASE_SEPOLIA_RPC_URL_2 = vm.envString("BASE_SEPOLIA_RPC_URL_2");

    function setUp() public {
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getBaseSepoliaConfig();
        fork = vm.createSelectFork(BASE_SEPOLIA_RPC_URL_2);
        vm.startPrank(owner);
        vaultFactory = new VaultFactory();
        vm.stopPrank();
        deal(networkConfig.usdc, user, 100 * 1e6);
    }

    function testCreateVault() public {
        vm.startPrank(user);
        address _vault = vaultFactory.createVault(user);
        Vault vault = Vault(_vault);
        assertEq(vault.owner(), user);
        vm.stopPrank();
    }

    function testDepositERC20() public {
        vm.startPrank(user);
        address _vault = vaultFactory.createVault(user);
        Vault vault = Vault(_vault);
        IERC20(networkConfig.usdc).approve(address(vault), 100 * 1e6);
        vault.depositERC20(networkConfig.usdc, 100 * 1e6);
        assertEq(IERC20(networkConfig.usdc).balanceOf(user), 0);
        assertEq(IERC20(networkConfig.usdc).balanceOf(address(vault)), 100 * 1e6);
        Vault.UserBalance memory userBalance = vault.getUserStruct(networkConfig.usdc);
        assertEq(userBalance.balance, 100 * 1e6);
        vm.stopPrank();
    }

    function testWithdrawERC20() public {
        vm.startPrank(user);
        address _vault = vaultFactory.createVault(user);
        Vault vault = Vault(_vault);
        IERC20(networkConfig.usdc).approve(address(vault), 100 * 1e6);
        vault.depositERC20(networkConfig.usdc, 100 * 1e6);
        vault.withdrawERC20(networkConfig.usdc, 100 * 1e6);
        assertEq(IERC20(networkConfig.usdc).balanceOf(user), 100 * 1e6);
        assertEq(IERC20(networkConfig.usdc).balanceOf(address(vault)), 0);
        vm.stopPrank();
    }
}
