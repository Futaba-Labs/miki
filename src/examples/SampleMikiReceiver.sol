// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IMikiReceiver } from "../interfaces/IMikiReceiver.sol";

contract SampleMikiReceiver is IMikiReceiver {
    event Received(address sender, address token, uint256 amount, bytes message);
    event Greeting(string greeting);

    fallback() external payable { }

    receive() external payable { }

    function mikiReceive(uint256, address, address token, uint256 amount, bytes calldata message) external payable {
        string memory greeting = abi.decode(message, (string));
        emit Received(msg.sender, token, amount, message);
        emit Greeting(greeting);
    }
}
