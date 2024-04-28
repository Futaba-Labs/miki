// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IMikiReceiver } from "../interfaces/IMikiReceiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract MikiRouterReceiver is Ownable {
    address public mikiRouter;
    address public mikiReceiver;

    /* ----------------------------- Erorrs -------------------------------- */

    error InvalidRouter();

    /* ----------------------------- Constructor -------------------------------- */
    constructor(address _mikiRouter, address _mikiReceiver, address _initialOwner) Ownable(_initialOwner) {
        mikiRouter = _mikiRouter;
        mikiReceiver = _mikiReceiver;
    }

    function mikiReceiveETH(uint256 srcChainId, uint256 amount, bytes calldata payload) external payable {
        if (msg.sender != mikiRouter) {
            revert InvalidRouter();
        }

        (address sender, address receiver, bytes memory messageWithId) =
            abi.decode(payload, (address, address, bytes));

        (bytes32 id, bytes memory message) = abi.decode(messageWithId, (bytes32, bytes));

        IMikiReceiver(mikiReceiver).mikiReceive{ value: amount }(
            srcChainId, sender, receiver, address(0), amount, message, id
        );
    }

    fallback() external payable { }

    receive() external payable { }
}
