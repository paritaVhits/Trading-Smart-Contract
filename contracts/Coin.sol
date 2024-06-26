// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";


contract Coin is ERC20{
      constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 4200000000 * (10**18)); // mint initial supply to contract creator
    }

   function burnToken(address to, uint256 amount) public {
        // Burn the specified amount of tokens belonging to the specified recipient
        _burn(to, amount);
    }
}