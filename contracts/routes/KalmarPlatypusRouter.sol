//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";
import "../interfaces/IKalmarTradingRoute.sol";
import "../interfaces/IPlatypus.sol";

contract KalmarPlatypusRouter is IKalmarTradingRoute, WhitelistedRole, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // curve-mim-usdt-usdc
    IPlatypus public constant platypusPool = IPlatypus(0x66357dCaCe80431aee0A7507e2E361B7e2402370);
    uint256 public constant deadline = 2 ** 256 - 1;

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

        uint256 balanceBefore = _dest.balanceOf(address(this));
        _src.safeTransferFrom(msg.sender, address(this), _srcAmount);
        _src.safeApprove(address(platypusPool), _srcAmount);
        (uint256 actualToAmount,) = platypusPool.swap(
          address(_src),
          address(_dest),
          _srcAmount,
          0,
          address(this),
          deadline
          );

        uint256 balanceAfter = _dest.balanceOf(address(this));
        _destAmount = balanceAfter.sub(balanceBefore);
        _dest.safeTransfer(msg.sender, _destAmount);
        emit Trade(_src, _srcAmount, _dest, actualToAmount);
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
        require(_src != _dest, "KalmR: Destination token can not be source token");
        if (!_isAvailableToken(address(_src)) || !_isAvailableToken(address(_dest))) {
            return 0;
        }

        (uint256 potentialOutcome,) = platypusPool.quotePotentialSwap(address(_src), address(_dest), _srcAmount);

        return potentialOutcome;
    }

    function isAvailableToken(
        address token
    )
        external
        view
        returns (bool)
    {
        return _isAvailableToken(token);
    }

    function _isAvailableToken(
        address token
    )
        internal
        view
        returns (bool)
    {
        address[] memory list = platypusPool.getTokenAddresses();
        for (uint256 i = 0; i < list.length; i++) {
            if(token == list[i]) {
                return true;
            }
        }
        return false;
    }
}
