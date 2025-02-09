// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./Vault.sol";
import "../script/HelperConfig.s.sol";

/**
 * @title VaultFactory
 * @author CentoAI
 * @notice Factory contract for deploying and managing individual Vault instances
 * @dev This contract inherits from HelperConfig to access network-specific configurations
 *      It maintains a registry of vault addresses mapped to their owners and handles
 *      the deployment of new vault instances with appropriate protocol integrations
 */
contract VaultFactory is HelperConfig {
    /// @notice Mapping from vault owner address to their vault contract address
    /// @dev One owner can only have one vault at a time in the current implementation
    mapping(address => address) public ownerToVaultAddress;

    /**
     * @notice Emitted when a new vault is created
     * @param owner The address of the vault owner
     * @param vault The address of the newly created vault contract
     */
    event VaultCreated(address indexed owner, address indexed vault);

    /// @notice Current network configuration containing protocol addresses
    /// @dev Retrieved from HelperConfig during construction
    HelperConfig.NetworkConfig public activeNetworkConfig;

    /**
     * @notice Initializes the VaultFactory with Base Sepolia network configurations
     * @dev Sets up the contract with predefined addresses for DeFi protocol integrations
     *      Currently hardcoded to Base Sepolia, could be made more flexible in future versions
     */
    constructor() {
        activeNetworkConfig = getArbitrumSepoliaConfig();
    }

    /**
     * @notice Creates a new Vault instance for the specified owner
     * @dev Deploys a new Vault contract with protocol addresses from activeNetworkConfig
     *      and registers it in the ownerToVaultAddress mapping
     * @param owner Address that will own and control the new vault
     * @return vault Address of the newly created vault contract
     * @custom:integration Integrates with Aave, Compound, and Uniswap protocols
     */
    function createVault(address owner) external returns (address vault) {
        // Deploy new Vault instance with protocol addresses from network config
        Vault vaultInstance = new Vault(
            owner,
            activeNetworkConfig.agent,
            activeNetworkConfig.aavePool,
            activeNetworkConfig.compoundUsdc,
            activeNetworkConfig.uniswapRouter,
            activeNetworkConfig.uniswapFactory
        );

        // Register the new vault in the ownership mapping
        ownerToVaultAddress[owner] = address(vaultInstance);

        // Emit event for indexing and tracking
        emit VaultCreated(owner, address(vaultInstance));

        return address(vaultInstance);
    }

    /**
     * @notice Retrieves the vault address associated with the caller
     * @dev Returns the vault address mapped to msg.sender
     * @return The address of the caller's vault, or zero address if none exists
     */
    function getVaultAddress() external view returns (address) {
        return ownerToVaultAddress[msg.sender];
    }
}
