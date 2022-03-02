// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

interface IPriceFeed {

    // --- Function ---
    function fetchPrice() external view returns (uint);
    function updatePrice() external returns (uint);
}
