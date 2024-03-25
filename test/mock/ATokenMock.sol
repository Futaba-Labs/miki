// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IATokenMock is IERC20 {
    function mint(address caller, address onBehalfOf, uint256 amount, uint256 index) external;
    function burn(address caller, address onBehalfOf, uint256 amount, uint256 index) external;
}

contract ATokenMock is ERC20, IATokenMock {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) { }

    function mint(address caller, address onBehalfOf, uint256 amount, uint256 index) public {
        _mint(onBehalfOf, amount);
    }

    function burn(address caller, address onBehalfOf, uint256 amount, uint256 index) public {
        _burn(onBehalfOf, amount);
    }
}
