//SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";
import "../interfaces/IKalmarTradingRoute.sol";
import "../interfaces/IUniswapV2Router.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

interface IKalmar{
    function isFeeOnTransferToken(
        IERC20 token
    )
    external
    view
    returns(bool);
}

contract KalmarMultiRouter2 is IKalmarTradingRoute, Ownable, WhitelistedRole, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Router[] public routers;
    IERC20[] public correspondentTokens;
    IERC20[] public correspondentTokens2;

    IERC20 public constant etherERC20 = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 public wETH;
    uint256 public constant amountOutMin = 1;
    uint256 public constant deadline = 2 ** 256 - 1;

    uint256 public allRoutersLength;

    IKalmar public kalm;

    constructor(
        address _kalm,
        IUniswapV2Router[] memory _routers,
        IERC20[] memory _correspondentTokens,
        IERC20[] memory _correspondentTokens2,
        IERC20 _wETH
    ) public {
        /* require(_routers.length >= 1 && _correspondentTokens.length == _routers.length - 1, "KalmR: Invalid lengths"); */
        kalm = IKalmar(_kalm);
        routers = _routers;
        correspondentTokens = _correspondentTokens;
        correspondentTokens2 = _correspondentTokens2;

        allRoutersLength = routers.length;

        wETH = _wETH;
    }

    function updateKalmar(
        address  _kalmAddr
    )
        public
        onlyOwner
    {
        kalm = IKalmar(_kalmAddr);
    }

    function isFeeOnTransferToken(address _token)
        public
        view
        returns (bool)
    {

        return kalm.isFeeOnTransferToken(IERC20(_token));
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

        IERC20 src;
        IERC20 dest;
        uint256 srcAmount;
        uint256 _beforeSrc;
        uint256 _afterSrc;
        uint256 _curr;

        if (_src == etherERC20) {
            require(msg.value == _srcAmount, "KalmR: Source amount mismatch");
            srcAmount = _srcAmount;
        } else {
            _beforeSrc = _src.balanceOf(address(this));
            _src.safeTransferFrom(msg.sender, address(this), _srcAmount);
            _afterSrc = _src.balanceOf(address(this));
            _curr = _afterSrc.sub(_beforeSrc);
            srcAmount = _curr;
        }

        // Exchange token pairs to each routes
        for (uint256 i = 0; i < routers.length; i++) {
            address[] memory path;
            if(i == 0){
              path = new address[](correspondentTokens.length.add(1));
              path[0] = _src == etherERC20 ? address(wETH) : address(_src);
              src = _src;
              for (uint256 j = 0; j < correspondentTokens.length; j++) {
                path[j+1] = address(correspondentTokens[j]);
                dest = correspondentTokens[j];
              }
            }else{
              path = new address[](correspondentTokens2.length.add(1));
              src = correspondentTokens2[0];
              for (uint256 j = 0; j < correspondentTokens2.length; j++) {
                path[j] = address(correspondentTokens2[j]);
              }
              path[path.length.sub(1)] = _dest == etherERC20 ? address(wETH) : address(_dest);
              dest = _dest;
            }

            if (src == etherERC20) {
                uint256[] memory amounts = routers[i].swapExactETHForTokens.value(srcAmount)(
                    amountOutMin,
                    path,
                    i == routers.length - 1 ? msg.sender : address(this),
                    deadline
                );
                srcAmount = amounts[amounts.length - 1];
            } else if (dest == etherERC20) {
                src.safeApprove(address(routers[i]), 0);
                src.safeApprove(address(routers[i]), srcAmount);

                uint256 _beforeSwap = (i == routers.length - 1 ? msg.sender : address(this)).balance;
                routers[i].swapExactTokensForETHSupportingFeeOnTransferTokens(
                    srcAmount,
                    amountOutMin,
                    path,
                    i == routers.length - 1 ? msg.sender : address(this),
                    deadline
                );
                uint256 _afterSwap = (i == routers.length - 1 ? msg.sender : address(this)).balance;
                srcAmount = _afterSwap.sub(_beforeSwap);

            } else {
                src.safeApprove(address(routers[i]), 0);
                src.safeApprove(address(routers[i]), srcAmount);

                uint256 _beforeSwap = dest.balanceOf(i == routers.length - 1 ? msg.sender : address(this));
                routers[i].swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    srcAmount,
                    amountOutMin,
                    path,
                    i == routers.length - 1 ? msg.sender : address(this),
                    deadline
                );
                uint256 _afterSwap = dest.balanceOf(i == routers.length - 1 ? msg.sender : address(this));
                srcAmount = _afterSwap.sub(_beforeSwap);

            }
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

        IERC20 src;
        IERC20 dest;
        uint256 srcAmount1 = _srcAmount;
        uint256 srcAmount2;
        // Fetch prices by token pairs to each routes
        for (uint256 i = 0; i < routers.length; i++) {
            src = _src;
            dest = _dest;

            if(i == 0){
              address[] memory path = new address[](correspondentTokens.length.add(1));
              path[0] = src == etherERC20 ? address(wETH) : address(src);
              for (uint256 j = 0; j < correspondentTokens.length; j++) {
                path[j+1] = address(correspondentTokens[j]);
              }
              uint256[] memory amounts = routers[i].getAmountsOut(srcAmount1, path);
              srcAmount1 = amounts[amounts.length - 1];
            }else{
              address[] memory path = new address[](correspondentTokens2.length.add(1));
              for (uint256 j = 0; j < correspondentTokens2.length; j++) {
                path[j] = address(correspondentTokens2[j]);
              }
              path[path.length.sub(1)] = dest == etherERC20 ? address(wETH) : address(dest);
              uint256[] memory amounts = routers[i].getAmountsOut(srcAmount1, path);
              srcAmount2 = amounts[amounts.length - 1];
            }

        }
        _destAmount = srcAmount2;

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
