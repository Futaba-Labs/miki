// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IATokenMock } from "./ATokenMock.sol";

contract AAVEV3PoolMock {
    address public aToken;

    constructor(address _aToken) {
        aToken = _aToken;
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) public {
        IATokenMock(aToken).mint(msg.sender, onBehalfOf, amount, 0);
    }
}
