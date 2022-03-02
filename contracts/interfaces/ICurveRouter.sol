//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

interface ICurveRouter {

    // def get_dy(i: int128, j: int128, dx: uint256) -> uint256:
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256 dy);
    // def get_dy_underlying(i: int128, j: int128, dx: uint256) -> uint256:
    // function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256 dy);

    // def exchange(i: int128, j: int128, dx: uint256, min_dy: uint256) -> uint256:
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256 dy);
    // def exchange_underlying(i: int128, j: int128, dx: uint256, min_dy: uint256) -> uint256:
    // function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256 dy);
}
