// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@balancer/balancer-v2-monorepo/pkg/interfaces/contracts/vault/IVault.sol";
import "@balancer/balancer-v2-monorepo/pkg/interfaces/contracts/vault/IFlashLoanRecipient.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

/**
 * @title Arbitrage
 * @author Cento-AI
 * @notice Executes arbitrage opportunities between two Uniswap-like DEXs using Balancer V2 Flash Loans.
 * @notice This contract is inherited by the Vault contract, and can be only used by the Vault contract.
 * @dev This contract borrows a flash loan, performs two consecutive swaps (e.g., DEX A → DEX B),
 * repays the loan, and sends profits to the contract owner.
 * @dev Note: The current implementation does not account for Balancer's flash loan fees (see critical warning).
 */
contract ArbitrageContract is IFlashLoanRecipient {
    /// @notice Balancer V2 Vault address (Base Sepolia)
    IVault private constant vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    /**
     * @dev Struct to encapsulate swap parameters for a single trade path.
     * @param routerPath Array with two elements: [firstSwapRouter, secondSwapRouter]
     * @param tokenPath Array with two elements: [tokenToBorrow, tokenToSwap]
     * @param fee Pool fee tier for Uniswap V3 swaps (e.g., 3000 = 0.3%)
     */
    struct Trade {
        address[] routerPath;
        address[] tokenPath;
        uint24 fee;
    }

    /**
     * @notice Emitted after a successful swap on a DEX.
     * @param tokenIn Address of the input token
     * @param tokenOut Address of the output token
     * @param amountIn Amount of tokenIn swapped
     * @param minAmountOut Minimum expected amount of tokenOut (slippage protection)
     */
    event TokensSwapped(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut);

    constructor() {}

    /**
     * @notice Initiates a flash loan for arbitrage execution
     * @dev Can only be called by the Vault contract
     * @param _routerPath [firstSwapRouter, secondSwapRouter] - Uniswap-compatible router addresses
     * @param _tokenPath [tokenToBorrow, tokenToSwap] - Token addresses for the arbitrage path
     * @param _fee Uniswap V3 pool fee tier for swaps
     * @param _flashAmount Amount of tokenToBorrow to flash loan
     */
    function executeTrade(address[] memory _routerPath, address[] memory _tokenPath, uint24 _fee, uint256 _flashAmount)
        internal
    {
        /// @dev Encode trade parameters for flash loan callback
        bytes memory data = abi.encode(Trade({routerPath: _routerPath, tokenPath: _tokenPath, fee: _fee}));

        /// @dev Configure flash loan parameters
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(_tokenPath[0]); // Token to borrow

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _flashAmount; // Loan amount

        /// @dev Trigger Balancer flash loan
        vault.flashLoan(this, tokens, amounts, data);
    }

    /**
     * @notice Callback function executed by Balancer Vault after loan approval
     * @dev This function contains core arbitrage logic
     * @param tokens Array of borrowed tokens (length = 1 in current implementation)
     * @param amounts Array of borrowed amounts (length = 1)
     * @param feeAmounts Array of flash loan fees (unused in current implementation)
     * @param userData Encoded Trade parameters from executeTrade
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        require(msg.sender == address(vault), "Unauthorized: Only Balancer Vault");

        /// @dev Decode trade parameters from userData
        Trade memory trade = abi.decode(userData, (Trade));
        uint256 flashAmount = amounts[0];

        /// @dev First swap: Borrowed token → Intermediate token
        _swapOnV3(
            trade.routerPath[0],
            /// @param routerPath[0] First DEX router (e.g., Uniswap)
            trade.tokenPath[0],
            /// @param tokenPath[0] Borrowed token address
            flashAmount,
            /// @param flashAmount Use entire flash loan amount
            trade.tokenPath[1],
            /// @param tokenPath[1] Token to receive
            0,
            /// @param 0 No minimum out (assuming optimistic arbitrage)
            trade.fee
        );
        /// @param fee Pool fee tier

        /// @dev Second swap: Intermediate token → Borrowed token
        _swapOnV3(
            trade.routerPath[1],
            /// @param routerPath[1] Second DEX router (e.g., Sushiswap)
            trade.tokenPath[1],
            /// @param tokenPath[1] Intermediate token
            IERC20(trade.tokenPath[1]).balanceOf(address(this)),
            /// @param IERC20(trade.tokenPath[1]).balanceOf(address(this)) Swap entire balance
            trade.tokenPath[0],
            /// @param trade.tokenPath[0] Borrowed token (to repay loan)
            flashAmount,
            /// @param flashAmount Minimum required to repay loan (slippage protection)
            trade.fee
        );
        /// @param fee Pool fee tier

        /// @dev Repay flash loan principal (WARNING: Missing fee repayment - see note)
        IERC20(trade.tokenPath[0]).transfer(address(this), flashAmount);
    }

    /**
     * @notice Executes a single exact-input swap arbitrage on Uniswap V3
     * @dev This function is used to execute an arbitrage without a flash loan
     * @dev Emits TokensSwapped event on success
     * @param _routerPath [firstSwapRouter, secondSwapRouter] - Uniswap-compatible router addresses
     * @param _tokenPath [tokenToBorrow, tokenToSwap] - Token addresses for the arbitrage path
     * @param _fee Uniswap V3 pool fee tier for swaps
     * @param _amount Amount of tokenToBorrow to swap
     */
    function ArbitrageWithoutFlashLoan(
        address[] memory _routerPath,
        address[] memory _tokenPath,
        uint24 _fee,
        uint256 _amount
    ) internal {
        Trade memory trade = Trade({routerPath: _routerPath, tokenPath: _tokenPath, fee: _fee});

        /// @dev First swap: Borrowed token → Intermediate token
        _swapOnV3(
            trade.routerPath[0],
            /// @param routerPath[0] First DEX router (e.g., Uniswap)
            trade.tokenPath[0],
            /// @param tokenPath[0] Borrowed token address
            _amount,
            /// @param _amount Use entire flash loan amount
            trade.tokenPath[1],
            /// @param trade.tokenPath[1] Token to receive
            0,
            /// @param 0 No minimum out (assuming optimistic arbitrage)
            trade.fee
        );
        /// @param fee Pool fee tier

        /// @dev Second swap: Intermediate token → Borrowed token
        _swapOnV3(
            trade.routerPath[1],
            /// @param routerPath[1] Second DEX router (e.g., Sushiswap)
            trade.tokenPath[1],
            /// @param tokenPath[1] Intermediate token
            IERC20(trade.tokenPath[1]).balanceOf(address(this)),
            /// @param IERC20(trade.tokenPath[1]).balanceOf(address(this)) Swap entire balance
            trade.tokenPath[0],
            /// @param trade.tokenPath[0] Borrowed token (to repay loan)
            _amount,
            /// @param _amount Minimum required to repay loan (slippage protection)
            trade.fee
        );
        /// @param fee Pool fee tier
    }

    /**
     * @notice Executes a single exact-input swap on Uniswap V3
     * @dev Emits TokensSwapped event on success
     * @param _router Uniswap V3 router address
     * @param _tokenIn Input token address
     * @param _amountIn Amount of tokenIn to swap
     * @param _tokenOut Output token address
     * @param _amountOut Minimum expected amount of tokenOut
     * @param _fee Pool fee tier (e.g., 3000 for 0.3%)
     */
    function _swapOnV3(
        address _router,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut,
        uint24 _fee
    ) internal {
        /// @dev Approve router to spend input tokens
        IERC20(_tokenIn).approve(_router, _amountIn);

        /// @dev Configure single-hop swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _fee,
            recipient: address(this),
            /// @param recipient Send output tokens to this contract
            deadline: block.timestamp,
            /// @param deadline Expire after current block
            amountIn: _amountIn,
            amountOutMinimum: _amountOut,
            /// @param amountOutMinimum Minimum output for successful swap
            sqrtPriceLimitX96: 0
        });
        /// @param sqrtPriceLimitX96 No price limit (accept any slippage)

        /// @dev Execute swap on specified router
        ISwapRouter(_router).exactInputSingle(params);
        emit TokensSwapped(_tokenIn, _tokenOut, _amountIn, _amountOut);
    }
}
