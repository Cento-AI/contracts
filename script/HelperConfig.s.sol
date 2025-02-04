// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Script, console2} from "forge-std/Script.sol";

contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error HelperConfig__InvalidChainId();

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/

    struct NetworkConfig {
        address weth; // Mode Network WETH
        address usdc; // Mode Network USDC
        address uniswapFactory; // Uniswap V3
        address uniswapRouter; //Uniswap V3
        address uniswapQouter; // Uniswap V3
        address forkedUniswapFactory; // Forked Uniswap V3
        address forkedUniswapRouter; // Forked Uniswap V3
        address forkedUniswapQouter; // Forked Uniswap V3
    }

    /*//////////////////////////////////////////////////////////////
                                CONFIGS
    //////////////////////////////////////////////////////////////*/
    function getBaseSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory BaseSepoliaConfig = NetworkConfig({
            weth: 0x4200000000000000000000000000000000000006,
            usdc: 0x036CbD53842c5426634e7929541eC2318f3dCF7e,
            uniswapFactory: 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24,
            uniswapRouter: 0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4,
            uniswapQouter: 0xC5290058841028F1614F3A6F0F5816cAd0df5E27,
            forkedUniswapFactory: 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865,
            forkedUniswapRouter: 0x1b81D678ffb9C0263b24A97847620C99d213eB14,
            forkedUniswapQouter: 0xB048Bbc1Ee6b733FFfCFb9e9CeF7375518e25997
        });
        return BaseSepoliaConfig;
    }

    /*//////////////////////////////////////////////////////////////
                              LOCAL CONFIG
    //////////////////////////////////////////////////////////////*/
    function getAnvilConfig() public pure returns (NetworkConfig memory) {
        console2.log("Testing On Anvil Network");
        NetworkConfig memory AnvilConfig = NetworkConfig({
            weth: address(0),
            usdc: address(1),
            uniswapFactory: address(2),
            uniswapRouter: address(3),
            uniswapQouter: address(6),
            forkedUniswapFactory: address(4),
            forkedUniswapRouter: address(5),
            forkedUniswapQouter: address(6)
        });
        return AnvilConfig;
    }
}
