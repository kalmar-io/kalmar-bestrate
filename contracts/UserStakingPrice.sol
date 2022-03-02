//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

import "./interfaces/IPriceFeed.sol";
import "./interfaces/IPancakeswapV2Pair.sol";
import "./interfaces/IStakingRewards.sol";

contract UserStakingPrice is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event PriceFeedUpdated(address priceFeedAddress);
    event WhitelistTradeAdded(address whitelist);
    event WhitelistTradeRemoved(address whitelist);

    address public singleStakePool = 0x557d49B7c30A0ae651097806846F4145feE366b5;
    address public kalmbusdLP = 0xb7890ab80570750564a810eF6F214f1893Feb602;
    address public priceFeedBUSD;

    mapping(address => bool) public whitelistTrade;

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

    function fetchBusdPrice() public view returns (uint) {
        uint fetchPrice = _fetchPrice();
        return fetchPrice;
    }

    function fetchKalmPrice() public view returns (uint256) {
        uint256 fetchPrice = _kalmPrice();
        return fetchPrice;
    }

    function getTokenPrice(address pairAddress, uint256 amount) external view returns(uint256)
    {
      uint256 result = _getTokenPrice(pairAddress,amount);
      return result;
    }

    function updatePriceFeed(address _priceFeedAddr) public onlyOwner {
      priceFeedBUSD = _priceFeedAddr;
      emit PriceFeedUpdated(_priceFeedAddr);
    }

    function userLpPrice(address user) public view returns (uint256)
    {
        uint256 userValue = (IERC20(kalmbusdLP).balanceOf(user) * _getLpPrice())/1e18;
        return userValue;
    }

    function userStakingPriceUSD(address user) public view returns (uint256)
    {
        uint256 userValue = _userStakingPriceUSD(user);
        return userValue;
    }

    function userStakingValue(address user) public view returns (uint256 fee, uint256 totalValue)
    {
        uint256 userLp = (IERC20(kalmbusdLP).balanceOf(user) * _getLpPrice())/1e18;
        uint256 userStake = _userStakingPriceUSD(user);
        uint256 total = userLp + userStake;
        if(whitelistTrade[user] == true){
          return (10000,total);
        }else{
          if(total < 200000000000000000000){
            return (50000,total);
          }
          return (25000,total);
        }

    }

    /* ================= Internal Function ================= */

    function _fetchPrice() internal view returns (uint) {
        uint fetchPrice = IPriceFeed(priceFeedBUSD).fetchPrice();
        return fetchPrice;
    }

    function _getTokenPrice(address pairAddress, uint256 amount) internal view returns(uint256)
    {
      IPancakeswapV2Pair pair = IPancakeswapV2Pair(pairAddress);
      (uint256 Res0, uint256 Res1,) = pair.getReserves();

      // decimals
      uint256 res1 = Res1*(10**18);
      return((amount*res1)/Res0); // return amount of token1 needed to buy token0
    }

    function _kalmPrice() internal view returns (uint256) {
        // amount of
        uint256 busdPERkalm = _getTokenPrice(kalmbusdLP,1000000000000000000)/1e18;
        uint256 kalmPrice = (busdPERkalm*_fetchPrice())/1e18;

        return kalmPrice;
    }

    function _getLpPrice() internal view returns(uint256)
    {
      IPancakeswapV2Pair pair = IPancakeswapV2Pair(kalmbusdLP);
      (uint256 Res0, uint256 Res1,) = pair.getReserves();
      uint totalSupply = pair.totalSupply();
      uint256 totalBusdPrice = (Res1 * _fetchPrice());
      uint256 totalKalmPrice = (Res0 * _kalmPrice());

      uint256 lpPrice = (totalBusdPrice + totalKalmPrice) / totalSupply;
      return lpPrice;

    }

    function _userStakingPriceUSD(address user) internal view returns (uint256)
    {
        uint256 userStake = IStakingRewards(singleStakePool).balanceOf(user);
        uint256 userValue = (userStake * _kalmPrice())/1e18;
        return userValue;
    }



}
