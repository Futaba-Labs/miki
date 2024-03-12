// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

contract HelloWorld {
    event Greeted(string greeting);

    fallback() external payable { }

    receive() external payable { }

    function greet(string memory greeting) public {
        emit Greeted(greeting);
    }
}
