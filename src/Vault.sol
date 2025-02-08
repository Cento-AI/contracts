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

    error InvalidProtocol(string protocol);
    error AerodromeNotImplemented();

    modifier onlyAgent() {
        require(msg.sender == agent, "Only agent");
        _;
    }

    modifier validLendingProtocol(string memory protocol) {
        if (
            keccak256(bytes(protocol)) != keccak256(bytes("aave")) &&
            keccak256(bytes(protocol)) != keccak256(bytes("compound"))
        ) {
            revert InvalidProtocol(protocol);
        }
        _;
    }

    modifier validLPProtocol(string memory protocol) {
        if (
            keccak256(bytes(protocol)) != keccak256(bytes("uniswap")) &&
            keccak256(bytes(protocol)) != keccak256(bytes("aerodrome"))
        ) {
            revert InvalidProtocol(protocol);
        }
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

    function lendTokens(
        string memory protocol,
        address token,
        uint256 amount
    ) external onlyAgent validLendingProtocol(protocol) {
        require(
            tokenAddressToStruct[token].balance >= amount,
            "Insufficient balance"
        );

        if (keccak256(bytes(protocol)) == keccak256(bytes("aave"))) {
            supplyLiquidityOnAave(token, amount);
            tokenAddressToStruct[token].investedInAave += amount;
        } else if (keccak256(bytes(protocol)) == keccak256(bytes("compound"))) {
            supplyLiquidityOnCompound(token, amount);
            tokenAddressToStruct[token].investedInCompound += amount;
        }

        tokenAddressToStruct[token].balance -= amount;
    }

    function withdrawLentTokens(
        string memory protocol,
        address token,
        uint256 amount
    )
        external
        onlyAgent
        validLendingProtocol(protocol)
        returns (uint256 amountWithdrawn)
    {
        if (keccak256(bytes(protocol)) == keccak256(bytes("aave"))) {
            require(
                tokenAddressToStruct[token].investedInAave >= amount,
                "Insufficient invested amount"
            );
            amountWithdrawn = withdrawLiquidityFromAave(token, amount);
            tokenAddressToStruct[token].investedInAave -= amount;
        } else if (keccak256(bytes(protocol)) == keccak256(bytes("compound"))) {
            require(
                tokenAddressToStruct[token].investedInCompound >= amount,
                "Insufficient invested amount"
            );
            amountWithdrawn = withdrawLiquidityFromCompound(token, amount);
            tokenAddressToStruct[token].investedInCompound -= amount;
        }

        tokenAddressToStruct[token].balance += amountWithdrawn;
        return amountWithdrawn;
    }

    // TODO Add aerodrome
    function addLiquidity(
        string memory protocol,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper
    ) external onlyAgent validLPProtocol(protocol) {
        require(
            tokenAddressToStruct[token0].balance >= amount0,
            "Insufficient balance token0"
        );
        require(
            tokenAddressToStruct[token1].balance >= amount1,
            "Insufficient balance token1"
        );

        if (keccak256(bytes(protocol)) == keccak256(bytes("uniswap"))) {
            supplyLiquidityOnUniswap(
                token0,
                token1,
                amount0,
                amount1,
                fee,
                tickLower,
                tickUpper
            );
            tokenAddressToStruct[token0].investedInUniswap += amount0;
            tokenAddressToStruct[token1].investedInUniswap += amount1;
        } else if (
            keccak256(bytes(protocol)) == keccak256(bytes("aerodrome"))
        ) {
            revert AerodromeNotImplemented();
        }

        tokenAddressToStruct[token0].balance -= amount0;
        tokenAddressToStruct[token1].balance -= amount1;
    }

    function removeLiquidity(
        string memory protocol,
        address token0,
        address token1,
        uint256 liquidityAmount
    ) external onlyAgent validLPProtocol(protocol) {
        if (keccak256(bytes(protocol)) == keccak256(bytes("uniswap"))) {
            withdrawLiquidityFromUniswap(
                token0,
                token1,
                3000, // default fee
                uint128(liquidityAmount)
            );
        } else if (
            keccak256(bytes(protocol)) == keccak256(bytes("aerodrome"))
        ) {
            revert AerodromeNotImplemented();
        }
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
