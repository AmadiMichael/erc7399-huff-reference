// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC20 } from "src/Solidity/lib/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000e18);
    }

    function mint(address to, uint256 amount) external returns (bool) {
        _mint(to, amount);
        return true;
    }
}
