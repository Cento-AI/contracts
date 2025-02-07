// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Vault
 * @author Cento-AI
 * @notice This contract is used to manage user balances for the Cento-AI protocol.
 * @notice This contract calls the LiquidityManager contract to mazimize profits on the user's balances.
 * @dev It allows users to deposit and withdraw ERC20 tokens.
 * @dev It also allows users to get their balance of a specific token.
 */
contract Vault is Ownable(msg.sender) {
    /// @notice Liquidity manager address.
    address public liquidityManager;

    /// @notice Mapping of user address to token address to balance.
    mapping(address => mapping(address => uint256))
        public userAddressToBalances;

    event ERC20Deposited(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event ERC20Withdrawn(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    modifier onlyLiquidityManager() {
        require(msg.sender == liquidityManager, "Only liquidity manager");
        _;
    }

    /**
     * @notice Deposit ERC20 tokens into the vault.
     * @param _token Token address to deposit.
     * @param _amount Amount of token to deposit.
     */
    function depositERC20(address _token, uint256 _amount) external {
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
        userAddressToBalances[msg.sender][_token] += _amount;
        emit ERC20Deposited(msg.sender, _token, _amount);
    }

    /**
     * @notice Withdraw ERC20 tokens from the vault.
     * @param _token Token address to withdraw.
     * @param _amount Amount of token to withdraw.
     */
    function withdrawERC20(address _token, uint256 _amount) external {
        require(
            userAddressToBalances[msg.sender][_token] >= _amount,
            "Insufficient balance"
        );
        IERC20(_token).approve(msg.sender, _amount);
        IERC20(_token).transferFrom(address(this), msg.sender, _amount);
        userAddressToBalances[msg.sender][_token] -= _amount;
        emit ERC20Withdrawn(msg.sender, _token, _amount);
    }

    /**
     * @notice Set the liquidity manager address.
     * @param _liquidityManager Liquidity manager address to set.
     */
    function setLiquidityManager(address _liquidityManager) public onlyOwner {
        liquidityManager = _liquidityManager;
    }

    /**
     * @notice Transfer ERC20 tokens to the liquidity manager.
     * @param _onBehalfOf Address of the user to transfer the tokens on behalf of to.
     * @param _asset Address of the token to transfer.
     * @param _amount Amount of tokens to transfer.
     */
    function transferERC20ToLiquidityManager(
        address _onBehalfOf,
        address _asset,
        uint256 _amount
    ) public onlyLiquidityManager {
        require(
            userAddressToBalances[_onBehalfOf][_asset] >= _amount,
            "Insufficient balance"
        );
        userAddressToBalances[_onBehalfOf][_asset] -= _amount;
        bool success = IERC20(_asset).transferFrom(
            address(this),
            liquidityManager,
            _amount
        );
        require(success, "Transfer failed");
    }

    /**
     * @notice Get the balance of a specific token for a user.
     * @param _user User address to get the balance of.
     * @param _token Token address to get the balance of.
     * @return balance Balance of the user for the token.
     */
    function getERC20Balance(
        address _user,
        address _token
    ) external view returns (uint256) {
        return userAddressToBalances[_user][_token];
    }
}
