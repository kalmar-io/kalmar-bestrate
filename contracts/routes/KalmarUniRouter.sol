//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";
import "../interfaces/IKalmarTradingRoute.sol";
import "../interfaces/IUniswapV2Router.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

interface IKalmar {
    function isFeeOnTransferToken(
        IERC20 token
    )
    external
    view
    returns(bool);
}

contract KalmarUniRouter is IKalmarTradingRoute, Ownable, WhitelistedRole, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Router public routers;
    IERC20[] public correspondentTokens;

    IERC20 public constant etherERC20 = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 public wETH;
    uint256 public constant amountOutMin = 1;
    uint256 public constant deadline = 2 ** 256 - 1;

    IKalmar public kalmarswap;

    constructor(
        address _kalm,
        IUniswapV2Router _routers,
        IERC20[] memory _correspondentTokens,
        IERC20 _wETH
    ) public {
        kalmarswap = IKalmar(_kalm);
        routers = _routers;
        correspondentTokens = _correspondentTokens;

        wETH = _wETH;
    }

    function updateSwap(
        address  _swapAddr
    )
        public
        onlyOwner
    {
        kalmarswap = IKalmar(_swapAddr);
    }

    function isFeeOnTransferToken(address _token)
        public
        view
        returns (bool)
    {

        return kalmarswap.isFeeOnTransferToken(IERC20(_token));
    }

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
        require(_src != _dest, "KalmR: Destination token can not be source token");

        IERC20 src = _src;
        IERC20 dest= _dest;
        uint256 srcAmount;

        if (_src == etherERC20) {
            require(msg.value == _srcAmount, "KalmR: Source amount mismatch");
            srcAmount = _srcAmount;
        } else {
            uint256 _beforeSrc = _src.balanceOf(address(this));
            _src.safeTransferFrom(msg.sender, address(this), _srcAmount);
            uint256 _afterSrc = _src.balanceOf(address(this));
            uint256 _curr = _afterSrc.sub(_beforeSrc);
            srcAmount = _curr;
        }

        uint256 pathLength = correspondentTokens.length;
        address[] memory path = new address[](pathLength.add(2));
        if(_src == etherERC20){
          path[0] = address(wETH);
          path[path.length.sub(1)] = address(_dest);
        }else if(_dest == etherERC20){
          path[0] = address(_src);
          path[path.length.sub(1)] = address(wETH);
        }else{
          path[0] = address(_src);
          path[path.length.sub(1)] = address(_dest);
        }
        // Exchange token pairs to each routes
        for (uint256 i = 1; i < path.length.sub(1); i++) {
          path[i] = address(correspondentTokens[i - 1]);
        }

          if (src == etherERC20) {
              uint256[] memory amounts = routers.swapExactETHForTokens.value(srcAmount)(
                  amountOutMin,
                  path,
                  msg.sender,
                  deadline
              );
              srcAmount = amounts[amounts.length - 1];
          } else if (dest == etherERC20) {
              src.safeApprove(address(routers), srcAmount);
              uint256 _beforeSwap = msg.sender.balance;
              routers.swapExactTokensForETHSupportingFeeOnTransferTokens(
                  srcAmount,
                  amountOutMin,
                  path,
                  msg.sender,
                  deadline
              );
              uint256 _afterSwap = msg.sender.balance;
              srcAmount = _afterSwap.sub(_beforeSwap);

          } else {
              src.safeApprove(address(routers), srcAmount);
              uint256 _beforeSwap = dest.balanceOf(msg.sender);
              routers.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                  srcAmount,
                  amountOutMin,
                  path,
                  msg.sender,
                  deadline
              );
              uint256 _afterSwap = dest.balanceOf(msg.sender);
              srcAmount = _afterSwap.sub(_beforeSwap);
          }

        _destAmount = srcAmount;

        emit Trade(_src, _srcAmount, _dest, _destAmount);
    }

    function getDestinationReturnAmount(
        IERC20 _src,
        IERC20 _dest,
        uint256 _srcAmount
    )
        external
        view
        returns(uint256 _destAmount)
    {
        require(_src != _dest, "KalmR: Destination token can not be source token");
        if (isDuplicatedTokenInRoutes(_src) || isDuplicatedTokenInRoutes(_dest)) {
            return 0;
        }

        uint256 pathLength = correspondentTokens.length;
        address[] memory path = new address[](pathLength.add(2));

        if(_src == etherERC20){
          path[0] = address(wETH);
          path[path.length.sub(1)] = address(_dest);
        }else if(_dest == etherERC20){
          path[0] = address(_src);
          path[path.length.sub(1)] = address(wETH);
        }else{
          path[0] = address(_src);
          path[path.length.sub(1)] = address(_dest);
        }
        // Exchange token pairs to each routes
        for (uint256 i = 1; i < path.length.sub(1); i++) {
          path[i] = address(correspondentTokens[i - 1]);
        }

        uint256[] memory amounts = routers.getAmountsOut(_srcAmount, path);
        _destAmount = amounts[amounts.length - 1];
    }

    function isDuplicatedTokenInRoutes(
        IERC20 token
    )
        internal
        view
        returns (bool)
    {
        if (token == etherERC20) {
            token = wETH;
        }
        for (uint256 i = 0; i < correspondentTokens.length; i++) {
            if(token == correspondentTokens[i]) {
                return true;
            }
        }
        return false;
    }
}
