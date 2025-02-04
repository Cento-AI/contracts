// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// Import necessary interfaces for Balancer Vault, Flash Loans, and Uniswap V3
import "@balancer/balancer-v2-monorepo/pkg/interfaces/contracts/vault/IVault.sol";
import "@balancer/balancer-v2-monorepo/pkg/interfaces/contracts/vault/IFlashLoanRecipient.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IQuoterV2} from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";

/**
 * @title Arbitrage
 * @author CentoAI
 * @notice Executes arbitrage opportunities between two Uniswap-like DEXs using Balancer V2 Flash Loans.
 * @dev This contract borrows a flash loan, performs two consecutive swaps (e.g., DEX A → DEX B),
 *      repays the loan, and sends profits to the contract owner.
 *      Note: The current implementation does not account for Balancer's flash loan fees (see critical warning).
 */
contract Arbitrage is IFlashLoanRecipient {
    /// @notice Balancer V2 Vault address (Ethereum mainnet)
    IVault private constant vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    /// @notice Owner address to receive arbitrage profits
    address public owner;

    /**
     * @dev Struct to encapsulate swap parameters for a single trade path.
     * @param routerPath Array with two elements: [firstSwapRouter, secondSwapRouter]
     * @param quoterPath Placeholder for future quoter integration (unused in current code)
     * @param tokenPath Array with two elements: [tokenToBorrow, tokenToSwap]
     * @param fee Pool fee tier for Uniswap V3 swaps (e.g., 3000 = 0.3%)
     */
    struct Trade {
        address[] routerPath;
        address[] quoterPath;
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

    /// @dev Sets the contract deployer as the owner
    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Initiates a flash loan for arbitrage execution
     * @dev Can be called by any external address (profits go to owner)
     * @param _routerPath [firstSwapRouter, secondSwapRouter] - Uniswap-compatible router addresses
     * @param _quoterPath Placeholder parameter (unused in current implementation)
     * @param _tokenPath [tokenToBorrow, tokenToSwap] - Token addresses for the arbitrage path
     * @param _fee Uniswap V3 pool fee tier for swaps
     * @param _flashAmount Amount of tokenToBorrow to flash loan
     */
    function executeTrade(
        address[] memory _routerPath,
        address[] memory _quoterPath,
        address[] memory _tokenPath,
        uint24 _fee,
        uint256 _flashAmount
    ) external {
        // Encode trade parameters for flash loan callback
        bytes memory data =
            abi.encode(Trade({routerPath: _routerPath, quoterPath: _quoterPath, tokenPath: _tokenPath, fee: _fee}));

        // Configure flash loan parameters
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(_tokenPath[0]); // Token to borrow

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _flashAmount; // Loan amount

        // Trigger Balancer flash loan
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

        // Decode trade parameters from userData
        Trade memory trade = abi.decode(userData, (Trade));
        uint256 flashAmount = amounts[0];

        // First swap: Borrowed token → Intermediate token
        _swapOnV3(
            trade.routerPath[0], // First DEX router (e.g., Uniswap)
            trade.tokenPath[0], // Borrowed token address
            flashAmount, // Use entire flash loan amount
            trade.tokenPath[1], // Token to receive
            0, // No minimum out (assuming optimistic arbitrage)
            trade.fee // Pool fee tier
        );

        // Second swap: Intermediate token → Borrowed token
        _swapOnV3(
            trade.routerPath[1], // Second DEX router (e.g., Sushiswap)
            trade.tokenPath[1], // Intermediate token
            IERC20(trade.tokenPath[1]).balanceOf(address(this)), // Swap entire balance
            trade.tokenPath[0], // Borrowed token (to repay loan)
            flashAmount, // Minimum required to repay loan (slippage protection)
            trade.fee // Pool fee tier
        );

        // Repay flash loan principal (WARNING: Missing fee repayment - see note)
        IERC20(trade.tokenPath[0]).transfer(address(vault), flashAmount);

        // Transfer remaining balance (profits) to owner
        uint256 profit = IERC20(trade.tokenPath[0]).balanceOf(address(this));
        IERC20(trade.tokenPath[0]).transfer(owner, profit);
    }

    // ========== INTERNAL FUNCTIONS ========== //

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
        // Approve router to spend input tokens
        IERC20(_tokenIn).approve(_router, _amountIn);

        // Configure single-hop swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _fee,
            recipient: address(this), // Send output tokens to this contract
            deadline: block.timestamp, // Expire after current block
            amountIn: _amountIn,
            amountOutMinimum: _amountOut, // Minimum output for successful swap
            sqrtPriceLimitX96: 0 // No price limit (accept any slippage)
        });

        // Execute swap on specified router
        ISwapRouter(_router).exactInputSingle(params);

        emit TokensSwapped(_tokenIn, _tokenOut, _amountIn, _amountOut);
    }
}
