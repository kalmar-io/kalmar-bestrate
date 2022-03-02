//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";
import "../interfaces/IKalmarTradingRoute.sol";
import "../interfaces/ICurveFTM.sol";

contract KalmarCurveRouterFTM is IKalmarTradingRoute, WhitelistedRole, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // curve1
    ICurveFTM public constant curvePool = ICurveFTM(0x3a1659Ddcf2339Be3aeA159cA010979FB49155FF);
    IERC20 public constant fusdt = IERC20(0x049d68029688eAbF473097a2fC38ef61633A3C7A); // 0
    IERC20 public constant btc = IERC20(0x321162Cd933E2Be498Cd2267a90534A804051b11); // 1
    IERC20 public constant eth = IERC20(0x74b23882a30290451A17c44f4F05243b6b58C76d); // 2

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
        _src.safeApprove(address(curvePool), _srcAmount);
        curvePool.exchange(i, j, _srcAmount, 0);

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

        return curvePool.get_dy(i, j, _srcAmount);
    }

    function getTokenIndexes(
        IERC20 _src,
        IERC20 _dest
    )
        public
        pure
        returns(uint256 i, uint256 j)
    {
        require(_src != _dest, "KalmyCurveRouter: Destination token can not be source token");
        i = uint256(-1);
        j = uint256(-1);
        i = _src == fusdt ? 0 : i;
        i = _src == btc ? 1 : i;
        i = _src == eth ? 2 : i;


        j = _dest == fusdt ? 0 : j;
        j = _dest == btc ? 1 : j;
        j = _dest == eth ? 2 : j;

        require(i != uint256(-1) && j != uint256(-1), "KalmyCurveRouter: Tokens not supported!");
    }
}
