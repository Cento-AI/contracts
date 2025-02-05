// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import {IPool} from "@aave/v3-core/contracts/interfaces/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SupplyLiquidity {
    IPool public aavePool;

    constructor(address _aavePool) {
        aavePool = IPool(_aavePool);
    }

    function supplyLiquidityOnAave(address _asset, uint256 _amount) external {
        IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
        IERC20(_asset).approve(address(aavePool), type(uint256).max);
        aavePool.supply(_asset, _amount, msg.sender, 0);
    }

    function withdrawLiquidityFromAave(
        address _asset,
        address _aaveAsset,
        uint256 _amount
    ) external {
        IERC20(_aaveAsset).transferFrom(msg.sender, address(this), _amount);
        aavePool.withdraw(_asset, _amount, msg.sender);
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
        external
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
}
