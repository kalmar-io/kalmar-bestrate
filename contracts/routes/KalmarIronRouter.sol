//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";
import "../interfaces/IKalmarTradingRoute.sol";
import "../interfaces/IIronRouter.sol";

contract KalmarIronRouter is IKalmarTradingRoute, WhitelistedRole, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant amountOutMin = 1;
    uint256 public constant deadline = 2 ** 256 - 1;

    IIronRouter public constant stablePool = IIronRouter(0x837503e8A8753ae17fB8C8151B8e6f586defCb57);
    IERC20 public constant usdc = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174); // 0
    IERC20 public constant usdt = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F); // 1
    IERC20 public constant dai = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063); // 2

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
        (uint256 i, uint256 j) = getTokenIndexes(_src, _dest);

        uint256 balanceBefore = _dest.balanceOf(address(this));
        _src.safeTransferFrom(msg.sender, address(this), _srcAmount);
        _src.safeApprove(address(stablePool), _srcAmount);
        stablePool.swap(uint8(i), uint8(j), _srcAmount, amountOutMin, deadline);

        uint256 balanceAfter = _dest.balanceOf(address(this));
        _destAmount = balanceAfter.sub(balanceBefore);
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
        (uint256 i, uint256 j) = getTokenIndexes(_src, _dest);

        return stablePool.calculateSwap(uint8(i), uint8(j), _srcAmount);
    }

    function getTokenIndexes(
        IERC20 _src,
        IERC20 _dest
    )
        public
        pure
        returns(uint256 i, uint256 j)
    {
        require(_src != _dest, "KalmCurveRouter: Destination token can not be source token");
        i = uint256(-1);
        j = uint256(-1);
        i = _src == usdc ? 0 : i;
        i = _src == usdt ? 1 : i;
        i = _src == dai ? 2 : i;

        j = _dest == usdc ? 0 : j;
        j = _dest == usdt ? 1 : j;
        j = _dest == dai ? 2 : j;
        require(i != uint256(-1) && j != uint256(-1), "KalmCurveRouter: Tokens not supported!");
    }
}
