//SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";
import "../interfaces/IKalmarTradingRoute.sol";
import "../interfaces/IAcryptoS.sol";

contract KalmarACryptoSV2Router is IKalmarTradingRoute, WhitelistedRole, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IAcryptoS public constant curvePool = IAcryptoS(0xc61639E5626EcfB0788b5308c67CBbBD1cAecBF0);
    IERC20 public constant otherToken = IERC20(0x7b65B489fE53fCE1F6548Db886C08aD73111DDd8); // 0
    IERC20 public constant busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // 1
    IERC20 public constant usdt = IERC20(0x55d398326f99059fF775485246999027B3197955); // 2
    IERC20 public constant dai = IERC20(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3); // 3
    IERC20 public constant usdc = IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d); // 4

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
        _destAmount = curvePool.exchange_underlying(i, j, _srcAmount, 0);

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

        return curvePool.get_dy_underlying(i, j, _srcAmount);
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
        i = _src == otherToken ? 0 : i;
        i = _src == busd ? 1 : i;
        i = _src == usdt ? 2 : i;
        i = _src == dai ? 3 : i;
        i = _src == usdc ? 4 : i;

        j = _dest == otherToken ? 0 : j;
        j = _dest == busd ? 1 : j;
        j = _dest == usdt ? 2 : j;
        j = _dest == dai ? 3 : j;
        j = _dest == usdc ? 4 : j;
        require(i != -1 && j != -1, "KalmarCurveRouter: Tokens are not supported!");
    }
}
