// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;
import "./Vault.sol";
import "../script/HelperConfig.s.sol";

contract VaultFactory is HelperConfig {
    mapping(address => address) public ownerToVaultAddress;
    event VaultCreated(address indexed owner, address indexed vault);
    HelperConfig.NetworkConfig public activeNetworkConfig;

    constructor() {
        activeNetworkConfig = getBaseSepoliaConfig();
    }

    function createVault() external returns (address vault) {
        Vault vaultInstance = new Vault(
            msg.sender,
            activeNetworkConfig.agent,
            activeNetworkConfig.aavePool,
            activeNetworkConfig.compoundUsdc,
            activeNetworkConfig.uniswapRouter,
            activeNetworkConfig.uniswapFactory
        );
        ownerToVaultAddress[msg.sender] = address(vaultInstance);
        emit VaultCreated(msg.sender, address(vaultInstance));
        return address(vaultInstance);
    }

    function getVaultAddress() external view returns (address) {
        return ownerToVaultAddress[msg.sender];
    }
}
