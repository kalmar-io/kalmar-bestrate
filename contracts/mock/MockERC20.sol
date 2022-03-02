// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    string public name = "Mock Kalmar Token";
    string public symbol = "MKALM";
    uint256 public decimals = 18;

    function mint(address account, uint256 amount) public returns (bool) {
        _mint(account, amount);
        return true;
    }
}
