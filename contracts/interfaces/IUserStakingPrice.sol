// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

interface IUserStakingPrice {

    // --- Function ---
    function fetchBusdPrice() external view returns (uint256);

    function fetchKalmPrice() external view returns (uint256);

    function userLpPrice() external view returns (uint256);

    function userStakingPriceUSD() external view returns (uint256);

    function userStakingValue(address user) external view returns (uint256 fee, uint256 totalValue);
}
