// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IMikiReceiver } from "../interfaces/IMikiReceiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract MikiRouterReceiver is Ownable {
    address public mikiRouter;
    address public mikiReceiver;
    /* ----------------------------- Events -------------------------------- */

    event SentMsgAndToken(
        uint256 _srcChainId, address _srcAddress, address _token, address _receiver, uint256 _amountLD, bytes _message
    );

    event SentMsg(uint256 _srcChainId, address _srcAddress, address _receiver, bytes _message);

    event FailedMsgAndToken(
        uint256 _srcChainId,
        address _srcAddress,
        address _token,
        address _receiver,
        uint256 _amountLD,
        bytes _message,
        string _reason
    );

    event FailedMsg(uint256 _srcChainId, address _srcAddress, address _receiver, bytes _message, string _reason);

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

        (address sender, address receiver, bytes memory message) = abi.decode(payload, (address, address, bytes));

        IMikiReceiver(mikiReceiver).mikiReceive{ value: amount }(
            srcChainId, sender, receiver, address(0), amount, message
        );
    }

    fallback() external payable { }

    receive() external payable { }
}
