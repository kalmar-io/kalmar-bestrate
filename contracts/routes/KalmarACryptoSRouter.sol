//SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";
import "../interfaces/IKalmarTradingRoute.sol";
import "../interfaces/IAcryptoRouter.sol";

contract KalmarACryptoSRouter is IKalmarTradingRoute, WhitelistedRole, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IAcryptoRouter public constant curvePool = IAcryptoRouter(0xb3F0C9ea1F05e312093Fdb031E789A756659B0AC);
    IERC20 public constant busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // 0
    IERC20 public constant usdt = IERC20(0x55d398326f99059fF775485246999027B3197955); // 1
    IERC20 public constant dai = IERC20(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3); // 2
    IERC20 public constant usdc = IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d); // 3

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
        (int128 i, int128 j) = getTokenIndexes(_src, _dest);

        _src.safeTransferFrom(msg.sender, address(this), _srcAmount);
        _src.safeApprove(address(curvePool), _srcAmount);
        _destAmount = curvePool.exchange(i, j, _srcAmount, 0);

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
        (int128 i, int128 j) = getTokenIndexes(_src, _dest);

        return curvePool.get_dy(i, j, _srcAmount);
    }

    function getTokenIndexes(
        IERC20 _src,
        IERC20 _dest
    )
        public
        pure
        returns(int128 i, int128 j)
    {
        require(_src != _dest, "KalmarCurveRouter: Destination token can not be source token");
        i = -1;
        j = -1;
        i = _src == busd ? 0 : i;
        i = _src == usdt ? 1 : i;
        i = _src == dai ? 2 : i;
        i = _src == usdc ? 3 : i;

        j = _dest == busd ? 0 : j;
        j = _dest == usdt ? 1 : j;
        j = _dest == dai ? 2 : j;
        j = _dest == usdc ? 3 : j;
        require(i != -1 && j != -1, "KalmarCurveRouter: Tokens are not supported!");
    }
}
