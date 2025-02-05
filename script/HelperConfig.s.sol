// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

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
        address weth;
        address usdc;
        address aaveUsdc; // "a tokens" recieved after supplying liquidity in aave V3
        address compoundUsdc;
        address uniswapFactory; // Uniswap V3
        address uniswapRouter; //Uniswap V3
        address uniswapQouter; // Uniswap V3
        address aavePool; // Aave V3
    }

    /*//////////////////////////////////////////////////////////////
                                CONFIGS
    //////////////////////////////////////////////////////////////*/
    function getBaseSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory BaseSepoliaConfig = NetworkConfig({
            weth: 0x4200000000000000000000000000000000000006,
            usdc: 0x036CbD53842c5426634e7929541eC2318f3dCF7e,
            aaveUsdc: 0xfE45Bf4dEF7223Ab1Bf83cA17a4462Ef1647F7FF,
            compoundUsdc: 0xe85D00f657F78c799ec4E9CAFd951ce5891bAde8,
            uniswapFactory: 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24,
            uniswapRouter: 0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4,
            uniswapQouter: 0xC5290058841028F1614F3A6F0F5816cAd0df5E27,
            aavePool: 0xbE781D7Bdf469f3d94a62Cdcc407aCe106AEcA74
        });
        return BaseSepoliaConfig;
    }

    function getAvaxFujiConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory AvaxFujiConfig = NetworkConfig({
            weth: address(0),
            usdc: 0x5425890298aed601595a70AB815c96711a31Bc65,
            aaveUsdc: 0x9CFcc1B289E59FBe1E769f020C77315DF8473760,
            compoundUsdc: address(0),
            uniswapFactory: address(0),
            uniswapRouter: address(0),
            uniswapQouter: address(0),
            aavePool: 0x8B9b2AF4afB389b4a70A474dfD4AdCD4a302bb40
        });
        return AvaxFujiConfig;
    }

    function getETHSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ETHSepoliaConfig = NetworkConfig({
            weth: 0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c,
            usdc: 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8,
            aaveUsdc: address(0),
            compoundUsdc: 0xE3E0106227181958aBfbA960C13d0Fe52c733265,
            uniswapFactory: address(0),
            uniswapRouter: address(0),
            uniswapQouter: address(0),
            aavePool: 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951
        });
        return ETHSepoliaConfig;
    }

    /*//////////////////////////////////////////////////////////////
                              LOCAL CONFIG
    //////////////////////////////////////////////////////////////*/
    function getAnvilConfig() public pure returns (NetworkConfig memory) {
        console2.log("Testing On Anvil Network");
        NetworkConfig memory AnvilConfig = NetworkConfig({
            weth: address(0),
            usdc: address(1),
            aaveUsdc: address(0),
            compoundUsdc: address(0),
            uniswapFactory: address(2),
            uniswapRouter: address(3),
            uniswapQouter: address(6),
            aavePool: address(7)
        });
        return AnvilConfig;
    }
}
