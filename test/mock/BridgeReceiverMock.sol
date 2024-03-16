// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMikiReceiver } from "../../src/interfaces/IMikiReceiver.sol";

contract BridgeReceiverMock {
    using Address for address;

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

    function receiveMsgWithAmount(
        uint256 _srcChainId,
        address _srcAddress,
        address _token,
        uint256 _amountLD,
        bytes memory _payload
    )
        external
    {
        (address sender, address receiver, bool isNative, bytes memory message) =
            abi.decode(_payload, (address, address, bool, bytes));

        if (isNative) {
            receiver.call{ value: _amountLD }("");
        } else {
            IERC20(_token).transfer(receiver, _amountLD);
        }

        try IMikiReceiver(receiver).mikiReceive(_srcChainId, sender, _token, _amountLD, message) {
            emit SentMsgAndToken(_srcChainId, sender, _token, receiver, _amountLD, message);
        } catch Error(string memory reason) {
            emit FailedMsgAndToken(_srcChainId, sender, _token, receiver, _amountLD, message, reason);
        } catch {
            emit FailedMsgAndToken(_srcChainId, sender, _token, receiver, _amountLD, message, "Unknown error");
        }
    }

    function receiveMsg(uint256 _srcChainId, address _srcAddress, bytes memory _payload) external {
        (address sender, address receiver, bytes memory message) = abi.decode(_payload, (address, address, bytes));

        try IMikiReceiver(receiver).mikiReceiveMsg(_srcChainId, sender, message) {
            emit SentMsg(_srcChainId, sender, receiver, message);
        } catch Error(string memory reason) {
            emit FailedMsg(_srcChainId, sender, receiver, message, reason);
        } catch {
            emit FailedMsg(_srcChainId, sender, receiver, message, "Unknown error");
        }
    }

    fallback() external payable { }

    receive() external payable { }
}
