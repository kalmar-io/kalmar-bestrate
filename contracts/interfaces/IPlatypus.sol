// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

interface IPlatypus {

    // --- Function ---
    function getTokenAddresses() external view returns (address[] memory);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256, uint256);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256, uint256);
}
