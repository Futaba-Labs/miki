// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IMikiAppReceiver } from "../interfaces/IMikiAppReceiver.sol";

contract SampleMikiReceiver is IMikiAppReceiver {
    event Received(address sender, address token, uint256 amount, bytes message);
    event Greeting(string greeting);

    fallback() external payable { }

    receive() external payable { }

    function mikiReceive(uint256, address, address token, uint256 amount, bytes calldata message) external payable {
        string memory greeting = abi.decode(message, (string));
        emit Received(msg.sender, token, amount, message);
        emit Greeting(greeting);
    }

    function mikiReceiveMsg(uint256, address, bytes calldata message) external payable {
        string memory greeting = abi.decode(message, (string));
        emit Greeting(greeting);
    }
}
