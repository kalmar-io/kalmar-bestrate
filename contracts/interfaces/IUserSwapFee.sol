// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

interface IUserSwapFee {

    // --- Function ---
    function userFeeValue(address user) external view returns (uint256);

    function maxFee() external view returns (uint256);

}
