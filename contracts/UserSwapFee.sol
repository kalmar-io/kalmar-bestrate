//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract UserSwapFee is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public fee;
    uint256 private MAX_FEE = 500000;
    address public kalm;
    uint256 public totalHolding;

    mapping(address => bool) public whitelistTrade;

    constructor(
        address _kalm
    ) public {
        kalm = _kalm;
    }

    /* ================= Setting Function ================= */

    function addWhitelistTrade(address _whitelist) public onlyOwner
    {
        whitelistTrade[address(_whitelist)] = true;
        emit WhitelistTradeAdded(_whitelist);
    }

    function removeWhitelistTrade(address _whitelist) public onlyOwner
    {
        whitelistTrade[address(_whitelist)] = false;
        emit WhitelistTradeRemoved(_whitelist);
    }

    function setFee(uint256 _fee) public onlyOwner
    {
        require(_fee <= MAX_FEE);
        fee = _fee;
        emit FeeSet(_fee);
    }

    function setHoldingAmount(uint256 _hold) public onlyOwner
    {
        require(_hold < 0);
        totalHolding = _hold;
        emit HoldingAmountSet(_hold);
    }

    /* ================= View Function ================= */
    function maxFee() public view returns (uint256)
    {
      return MAX_FEE;
    }

    function userFeeValue(address user) public view returns (uint256)
    {
      // [No fee] user is whitelist or kalm is zero address
      if(whitelistTrade[user] == true || kalm == address(0)){
        return 0;
      }

      // [Fee] holding kalm less than totalHolding
      if(IERC20(kalm).balanceOf(user) > totalHolding){
        return 0;
      } else {
        return fee;
      }

    }

    /* ================= Event Function ================= */

    event WhitelistTradeAdded(address whitelist);
    event WhitelistTradeRemoved(address whitelist);
    event FeeSet(uint256 fee);
    event HoldingAmountSet(uint256 hold);
}
