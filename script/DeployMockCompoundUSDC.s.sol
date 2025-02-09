// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {MockCompoundUSDC} from "../src/mocks/MockCompoundUSDC.sol";

contract DeployMockCompoundUSDC is Script {
    function run() external returns (MockCompoundUSDC) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MockCompoundUSDC mockCompoundUSDC = new MockCompoundUSDC();

        vm.stopBroadcast();

        return (mockCompoundUSDC);
    }
}
