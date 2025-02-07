// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IPool} from "@aave/v3-core/contracts/interfaces/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CometMainInterface} from "./interfaces/IComet.sol";
import {CometExtInterface} from "./interfaces/ICometExt.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {TickMath} from "./lib/TickMath.sol";
import {LiquidityAmounts} from "./lib/LiquidityAmounts.sol";

/**
 * @title LiquidityManager
 * @author Cento-AI
 * @notice Contract that integrates with aave and compound protocols to supply and withdraw liquidity.
 * @notice Contract to handle token swaps and liquidity additions on Uniswap.
 * @dev Integrates with a vault to manage user funds for swaps and liquidity.
 * @dev For compound finance, only USDC investment is available for now.
 */
contract LiquidityManager {
    IPool public aavePool;
    CometMainInterface public compoundUsdc;

    // Uniswap V3 components
    ISwapRouter public immutable uniswapRouter;
    IUniswapV3Factory public immutable uniswapFactory;
    address public vault;

    event TokensSwapped(
        address indexed protocol, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut
    );
    event LiquidityAdded(
        address indexed pool, address token0, address token1, uint128 liquidity, uint256 amount0, uint256 amount1
    );
    event LiquiditySupplied(string protocol, address asset, uint256 amount, address user);

    /**
     *
     * @param _aavePool Aave V3 pool address.
     * @param _compoundUsdc Compound USDC address.(Currently only USDC supported for compound).
     * @param _uniswapRouter Uniswap V3 router address.
     * @param _uniswapFactory Uniswap V3 factory address.
     * @param _vault Vault address to manage user funds.
     * @dev Constructor to set the addresses of the Aave pool, Compound USDC, Uniswap router, Uniswap factory, and vault.
     */
    constructor(
        address _aavePool,
        address _compoundUsdc,
        address _uniswapRouter,
        address _uniswapFactory,
        address _vault
    ) {
        aavePool = IPool(_aavePool);
        compoundUsdc = CometMainInterface(_compoundUsdc);
        uniswapRouter = ISwapRouter(_uniswapRouter);
        uniswapFactory = IUniswapV3Factory(_uniswapFactory);
        vault = _vault;
    }

    function supplyLiquidityOnAave(address _asset, uint256 _amount) external {
        require(IERC20(_asset).allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance");
        bool approvedUser = IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
        require(approvedUser, "Transfer of asset into this contract failed");
        bool approvedAave = IERC20(_asset).approve(address(aavePool), _amount);
        require(approvedAave, "Approval of asset into Aave pool failed");
        aavePool.supply(_asset, _amount, msg.sender, 0);
        emit LiquiditySupplied("Aave", _asset, _amount, msg.sender);
    }

    function supplyLiquidityOnCompound(address _asset, uint256 _amount) external {
        require(IERC20(_asset).allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance");
        bool approvedUser = IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
        require(approvedUser, "Transfer of asset into this contract failed");
        bool approvedCompound = IERC20(_asset).approve(address(compoundUsdc), _amount);
        require(approvedCompound, "Approval of asset into Compound failed");
        compoundUsdc.supplyTo(msg.sender, _asset, _amount);
        emit LiquiditySupplied("Compound", _asset, _amount, msg.sender);
    }

    function withdrawLiquidityFromAave(address _asset, address _aaveAsset, uint256 _amount)
        external
        returns (uint256 amountWithdrawn)
    {
        (uint256 collateral,,,,,) = getAaveLiquidityStatus(msg.sender);
        require(collateral >= _amount, "Cannot withdraw more than borrowed");
        bool success = IERC20(_aaveAsset).transferFrom(msg.sender, address(this), _amount);
        require(success, "Transfer of aave asset into this contract failed");
        amountWithdrawn = aavePool.withdraw(_asset, _amount, msg.sender);
    }

    function withdrawLiquidityFromCompound(address _asset, uint256 _amount) external {
        uint256 collateral = getCompoundLiquidityStatus(msg.sender);
        require(collateral >= _amount, "Cannot withdraw more than borrowed");
        compoundUsdc.withdrawFrom(msg.sender, address(this), _asset, _amount);
    }

    // ========== UNISWAP SWAP FUNCTIONALITY ========== //

    /**
     *
     * @param tokenIn token to swap from
     * @param tokenOut token to swap to
     * @param amountIn amount of tokenIn to swap
     * @param amountOutMin minimum amount of tokenOut to receive
     * @param fee fee tier for the swap
     * @return amountOut amount of tokenOut received
     */
    function swapOnUniswap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin, uint24 fee)
        external
        returns (uint256 amountOut)
    {
        // Transfer from vault and approve
        require(IERC20(tokenIn).transferFrom(vault, address(this), amountIn), "Vault transfer failed");
        IERC20(tokenIn).approve(address(uniswapRouter), amountIn);

        // Execute swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: vault, // Output to vault
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        });

        amountOut = uniswapRouter.exactInputSingle(params);
        emit TokensSwapped(address(uniswapRouter), tokenIn, tokenOut, amountIn, amountOut);
    }

    //
    // ========== UNISWAP LIQUIDITY FUNCTIONALITY ========== //

    /**
     * @notice Add liquidity directly to a Uniswap V3 pool
     * @param tokenA First token in pair
     * @param tokenB Second token in pair
     * @param amountADesired Max amount of tokenA to add
     * @param amountBDesired Max amount of tokenB to add
     * @param fee Pool fee tier (e.g., 3000 = 0.3%)
     * @param tickLower Lower tick boundary
     * @param tickUpper Upper tick boundary
     */
    function addLiquidityToPool(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper
    ) external returns (uint128 liquidity) {
        // Get pool address
        address pool = uniswapFactory.getPool(tokenA, tokenB, fee);
        require(pool != address(0), "Pool doesn't exist");

        // Sort tokens
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        // Transfer tokens from vault
        uint256 amount0 = tokenA == token0 ? amountADesired : amountBDesired;
        uint256 amount1 = tokenA == token0 ? amountBDesired : amountADesired;

        require(IERC20(token0).transferFrom(vault, address(this), amount0), "Token0 transfer failed");
        require(IERC20(token1).transferFrom(vault, address(this), amount1), "Token1 transfer failed");

        // Approve pool
        IERC20(token0).approve(pool, amount0);
        IERC20(token1).approve(pool, amount1);

        // Get current pool price
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(pool).slot0();

        // Calculate liquidity using Uniswap libraries
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        liquidity =
            LiquidityAmounts.getLiquidityForAmounts(sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, amount0, amount1);

        // Add liquidity directly to pool
        (uint256 amount0Actual, uint256 amount1Actual) = IUniswapV3Pool(pool).mint(
            address(this), // Recipient (this contract)
            tickLower,
            tickUpper,
            liquidity,
            abi.encode(msg.sender) // Callback data
        );

        emit LiquidityAdded(pool, token0, token1, liquidity, amount0Actual, amount1Actual);
    }

    /**
     * @notice Returns the user account data across all the reserves
     * @param _user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     */
    function getAaveLiquidityStatus(address _user)
        public
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return aavePool.getUserAccountData(_user);
    }

    function getCompoundLiquidityStatus(address _user) public view returns (uint256 balance) {
        balance = compoundUsdc.balanceOf(_user);
    }
}
