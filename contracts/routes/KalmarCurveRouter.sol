//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";
import "../interfaces/IKalmarTradingRoute.sol";
import "../interfaces/ICurve2P.sol";

contract KalmarCurveRouter is IKalmarTradingRoute, WhitelistedRole, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ICurve2P public constant curvePool = ICurve2P(0x872686B519E06B216EEf150dC4914f35672b0954);
    IERC20 public constant usdc = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75); // 0
    IERC20 public constant dai = IERC20(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E); // 1
    IERC20 public constant tusd = IERC20(0x9879aBDea01a879644185341F7aF7d8343556B7a); // 2
    IERC20 public constant frax = IERC20(0xdc301622e621166BD8E82f2cA0A26c13Ad0BE355); // 3

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
        curvePool.exchange(int128(i), int128(j), _srcAmount, 0);

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

        return curvePool.get_dy(int128(i), int128(j), _srcAmount);
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
        i = _src == usdc ? 0 : i;
        i = _src == dai ? 1 : i;
        i = _src == tusd ? 2 : i;
        i = _src == frax ? 3 : i;

        j = _dest == usdc ? 0 : j;
        j = _dest == dai ? 1 : j;
        j = _dest == tusd ? 2 : j;
        j = _dest == frax ? 3 : j;


        require(i != uint256(-1) && j != uint256(-1), "KalmyCurveRouter: Tokens not supported!");
    }
}
