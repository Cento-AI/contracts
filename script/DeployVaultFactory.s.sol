// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {VaultFactory} from "../src/VaultFactory.sol";

contract DeployVaultFactory is Script {
    function run() external returns (VaultFactory) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy VaultFactory with the owner set to msg.sender
        VaultFactory vaultFactory = new VaultFactory();

        vm.stopBroadcast();

        return (vaultFactory);
    }
}
