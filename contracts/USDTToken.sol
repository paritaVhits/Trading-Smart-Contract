// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";

contract USDTToken is ERC20 {
    constructor() ERC20("USDTToken", "USDT") {
        _mint(msg.sender, 4200000000 * (10**18)); // mint initial supply to contract creator
    }
}