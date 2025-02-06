// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import {IPool} from "@aave/v3-core/contracts/interfaces/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CometMainInterface} from "./interfaces/IComet.sol";
import {CometExtInterface} from "./interfaces/ICometExt.sol";

/**
 * @title LiquidityManager
 * @author Cento-AI
 * @notice Contract that integrates with aave and compound protocols to supply and withdraw liquidity.
 * @dev For compound finance, only USDC investment is available for now.
 */
contract LiquidityManager {
    IPool public aavePool;
    CometMainInterface public compoundUsdc;

    event LiquiditySupplied(
        string protocol,
        address asset,
        uint256 amount,
        address user
    );

    /**
     *
     * @param _aavePool Aave V3 pool address.
     * @param _compoundUsdc Compound USDC address.(Currently only USDC supported for compound).
     */
    constructor(address _aavePool, address _compoundUsdc) {
        aavePool = IPool(_aavePool);
        compoundUsdc = CometMainInterface(_compoundUsdc);
    }

    function supplyLiquidityOnAave(address _asset, uint256 _amount) external {
        require(
            IERC20(_asset).allowance(msg.sender, address(this)) >= _amount,
            "Insufficient allowance"
        );
        bool approvedUser = IERC20(_asset).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(approvedUser, "Transfer of asset into this contract failed");
        bool approvedAave = IERC20(_asset).approve(address(aavePool), _amount);
        require(approvedAave, "Approval of asset into Aave pool failed");
        aavePool.supply(_asset, _amount, msg.sender, 0);
        emit LiquiditySupplied("Aave", _asset, _amount, msg.sender);
    }

    function supplyLiquidityOnCompound(
        address _asset,
        uint256 _amount
    ) external {
        require(
            IERC20(_asset).allowance(msg.sender, address(this)) >= _amount,
            "Insufficient allowance"
        );
        bool approvedUser = IERC20(_asset).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(approvedUser, "Transfer of asset into this contract failed");
        bool approvedCompound = IERC20(_asset).approve(
            address(compoundUsdc),
            _amount
        );
        require(approvedCompound, "Approval of asset into Compound failed");
        compoundUsdc.supplyTo(msg.sender, _asset, _amount);
        emit LiquiditySupplied("Compound", _asset, _amount, msg.sender);
    }

    function withdrawLiquidityFromAave(
        address _asset,
        address _aaveAsset,
        uint256 _amount
    ) external returns (uint256 amountWithdrawn) {
        (uint256 collateral, , , , , ) = getAaveLiquidityStatus(msg.sender);
        require(collateral >= _amount, "Cannot withdraw more than borrowed");
        bool success = IERC20(_aaveAsset).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(success, "Transfer of aave asset into this contract failed");
        amountWithdrawn = aavePool.withdraw(_asset, _amount, msg.sender);
    }

    function withdrawLiquidityFromCompound(
        address _asset,
        uint256 _amount
    ) external {
        uint256 collateral = getCompoundLiquidityStatus(msg.sender);
        require(collateral >= _amount, "Cannot withdraw more than borrowed");
        compoundUsdc.withdrawFrom(msg.sender, address(this), _asset, _amount);
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
    function getAaveLiquidityStatus(
        address _user
    )
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

    function getCompoundLiquidityStatus(
        address _user
    ) public view returns (uint256 balance) {
        balance = compoundUsdc.balanceOf(_user);
    }
}
