// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IATokenMock } from "./ATokenMock.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AAVEV3PoolMock {
    address public aToken;

    constructor(address _aToken) {
        aToken = _aToken;
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) public {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        IATokenMock(aToken).mint(msg.sender, onBehalfOf, amount, 0);
    }

    function withdraw(address token, uint256 amount, address to) public returns (uint256) {
        IATokenMock(aToken).burn(msg.sender, to, amount, 0);
        IERC20(token).transfer(to, amount);

        return amount;
    }
}
