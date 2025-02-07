// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LiquidityManager.sol";

/**
 * @title Vault
 * @author Cento-AI
 * @notice This contract is used to manage user balances for the Cento-AI protocol.
 * @notice This contract calls the LiquidityManager contract to mazimize profits on the user's balances.
 * @dev It allows users to deposit and withdraw ERC20 tokens.
 * @dev It also allows users to get their balance of a specific token.
 */
contract Vault is Ownable, LiquidityManager {
    /// @notice Liquidity manager address.
    address public liquidityManager;

    address public agent;

    struct UserBalance {
        address asset;
        uint256 balance;
        uint256 investedInAave;
        uint256 investedInCompound;
        uint256 investedInUniswap;
    }

    /// @notice Mapping of user address to token address to struct.
    mapping(address => UserBalance) public tokenAddressToStruct;

    event ERC20Deposited(address indexed token, uint256 amount);
    event ERC20Withdrawn(address indexed token, uint256 amount);

    modifier onlyAgent() {
        require(msg.sender == agent, "Only agent");
        _;
    }

    constructor(
        address _owner,
        address _agent,
        address _aavePool,
        address _compoundUsdc,
        address _uniswapRouter,
        address _uniswapFactory
    )
        Ownable(_owner)
        LiquidityManager(
            _aavePool,
            _compoundUsdc,
            _uniswapRouter,
            _uniswapFactory
        )
    {
        agent = _agent;
    }

    /**
     * @notice Deposit ERC20 tokens into the vault.
     * @param _token Token address to deposit.
     * @param _amount Amount of token to deposit.
     */
    function depositERC20(address _token, uint256 _amount) external onlyOwner {
        require(
            IERC20(_token).allowance(msg.sender, address(this)) >= _amount,
            "Insufficient allowance"
        );
        bool success = IERC20(_token).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(success, "Transfer failed");
        tokenAddressToStruct[_token].balance += _amount;
        emit ERC20Deposited(_token, _amount);
    }

    /**
     * @notice Withdraw ERC20 tokens from the vault.
     * @param _token Token address to withdraw.
     * @param _amount Amount of token to withdraw.
     */
    function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
        require(
            tokenAddressToStruct[_token].balance >= _amount,
            "Insufficient balance"
        );
        IERC20(_token).approve(owner(), _amount);
        bool success = IERC20(_token).transfer(owner(), _amount);
        require(success, "Transfer failed");
        tokenAddressToStruct[_token].balance -= _amount;
        emit ERC20Withdrawn(_token, _amount);
    }

    /**
     * @notice Set the agent address.
     * @param _agent Agent address to set.
     */
    function setAgent(address _agent) public onlyOwner {
        agent = _agent;
    }

    function lendOnAave(address _asset, uint256 _amount) external onlyAgent {
        require(
            tokenAddressToStruct[_asset].balance >= _amount,
            "Insufficient balance"
        );
        supplyLiquidityOnAave(_asset, _amount);
        tokenAddressToStruct[_asset].balance -= _amount;
        tokenAddressToStruct[_asset].investedInAave += _amount;
    }

    function lendOnCompound(
        address _asset,
        uint256 _amount
    ) external onlyAgent {
        require(
            tokenAddressToStruct[_asset].balance >= _amount,
            "Insufficient balance"
        );
        supplyLiquidityOnCompound(_asset, _amount);
        tokenAddressToStruct[_asset].balance -= _amount;
        tokenAddressToStruct[_asset].investedInCompound += _amount;
    }

    function lendOnUniswap(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        uint24 _fee,
        int24 _tickLower,
        int24 _tickUpper
    ) external onlyAgent {
        require(
            tokenAddressToStruct[_tokenA].balance >= _amountA,
            "Insufficient balance"
        );
        require(
            tokenAddressToStruct[_tokenB].balance >= _amountB,
            "Insufficient balance"
        );
        supplyLiquidityOnUniswap(
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            _fee,
            _tickLower,
            _tickUpper
        );
        tokenAddressToStruct[_tokenA].balance -= _amountA;
        tokenAddressToStruct[_tokenB].balance -= _amountB;
        tokenAddressToStruct[_tokenA].investedInUniswap += _amountA;
        tokenAddressToStruct[_tokenB].investedInUniswap += _amountB;
    }

    function swapOnUniswap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint24 _fee
    ) external onlyAgent returns (uint256 amountOut) {
        require(
            tokenAddressToStruct[_tokenIn].balance >= _amountIn,
            "Insufficient balance"
        );
        amountOut = swapOnUniswap(_tokenIn, _tokenOut, _amountIn, 1, _fee);
        tokenAddressToStruct[_tokenIn].balance -= _amountIn;
        tokenAddressToStruct[_tokenOut].balance += amountOut;
    }

    function withdrawFromAave(
        address _asset,
        uint256 _amount
    ) external onlyAgent returns (uint256 amountWithdrawn) {
        amountWithdrawn = withdrawLiquidityFromAave(_asset, _amount);
        tokenAddressToStruct[_asset].balance += _amount;
        tokenAddressToStruct[_asset].investedInAave -= _amount;
    }

    function withdrawFromCompound(
        address _asset,
        uint256 _amount
    ) external onlyAgent returns (uint256 amountWithdrawn) {
        amountWithdrawn = withdrawLiquidityFromCompound(_asset, _amount);
        tokenAddressToStruct[_asset].balance += _amount;
        tokenAddressToStruct[_asset].investedInCompound -= _amount;
    }

    function withdrawFromUniswap(
        address _tokenA,
        address _tokenB,
        uint24 _fee,
        uint128 _liquidityToRemove
    ) external onlyAgent {
        withdrawLiquidityFromUniswap(
            _tokenA,
            _tokenB,
            _fee,
            _liquidityToRemove
        );
    }

    /**
     * @notice Get the struct details for a token..
     * @param _token Token address to get the balance of.
     * @return balance Balance of the user for the token.
     */
    function getStruct(
        address _token
    ) external view returns (UserBalance memory) {
        return tokenAddressToStruct[_token];
    }
}
