//SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";
import "../interfaces/IKalmarTradingRoute.sol";
import "../interfaces/IEllipsisRouter.sol";

contract KalmarEllipsis4PRouter is IKalmarTradingRoute, WhitelistedRole, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IEllipsisRouter public constant curvePool = IEllipsisRouter(0x8D7408C2b3154F9f97fc6dd24cd36143908d1E52);
    IERC20 public constant busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 public constant usdc = IERC20(0xaF4dE8E872131AE328Ce21D909C74705d3Aaf452);
    IERC20 public constant usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 public constant otherToken = IERC20(0x14016E85a25aeb13065688cAFB43044C2ef86784); // 0

    function trade(
        IERC20 _src,
        IERC20 _dest,
        uint256 _srcAmount
    )
        public
        payable
        onlyWhitelisted
        nonReentrant
        returns(uint256 _destAmount)
    {
        require(_src != _dest, "destination token can not be source token");
        int128 i = -1;
        int128 j = -1;
        i = _src == otherToken ? 0 : i;
        i = _src == usdc ? 2 : i;
        i = _src == usdt ? 3 : i;
        i = _src == busd ? 1 : i;

        j = _dest == busd ? 1 : j;
        j = _dest == usdc ? 2 : j;
        j = _dest == usdt ? 3 : j;
        j = _dest == otherToken ? 0 : j;
        require(i != -1 && j != -1, "tokens are not supported!");

        uint256 balanceBefore = _dest.balanceOf(address(this));
        _src.safeTransferFrom(msg.sender, address(this), _srcAmount);
        _src.safeApprove(address(curvePool), _srcAmount);
        curvePool.exchange_underlying(i, j, _srcAmount, 0);
        uint256 balanceAfter = _dest.balanceOf(address(this));
        _destAmount = balanceAfter - balanceBefore;
        _dest.safeTransfer(msg.sender, _destAmount);
        emit Trade(_src, _srcAmount, _dest, _destAmount);
    }

    function getDestinationReturnAmount(
        IERC20 _src,
        IERC20 _dest,
        uint256 _srcAmount
    )
        public
        view
        returns(uint256 _destAmount)
    {
        require(_src != _dest, "destination token can not be source token");
        int128 i = -1;
        int128 j = -1;
        i = _src == otherToken ? 0 : i;
        i = _src == usdc ? 2 : i;
        i = _src == usdt ? 3 : i;
        i = _src == busd ? 1 : i;

        j = _dest == busd ? 1 : j;
        j = _dest == usdc ? 2 : j;
        j = _dest == usdt ? 3 : j;
        j = _dest == otherToken ? 0 : j;
        require(i != -1 && j != -1, "tokens are not supported!");

        return curvePool.get_dy_underlying(i, j, _srcAmount);
    }
}
