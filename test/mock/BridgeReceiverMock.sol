// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMikiReceiver } from "../../src/interfaces/IMikiReceiver.sol";

contract BridgeReceiverMock {
    using Address for address;

    address public mikiReceiver;

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

    constructor(address _mikiReceiver) {
        mikiReceiver = _mikiReceiver;
    }

    function receiveMsgWithAmount(
        uint256 _srcChainId,
        address _srcAddress,
        address _token,
        uint256 _amountLD,
        bytes memory _payload
    )
        external
        payable
    {
        (address sender, address receiver, bool isNative, bytes memory messageWithId) =
            abi.decode(_payload, (address, address, bool, bytes));

        (bytes32 id, bytes memory message) = abi.decode(messageWithId, (bytes32, bytes));

        if (isNative) {
            IMikiReceiver(mikiReceiver).mikiReceive{ value: _amountLD }(
                _srcChainId, sender, receiver, address(0), _amountLD, message, id
            );
        } else {
            IERC20(_token).transfer(mikiReceiver, _amountLD);
            IMikiReceiver(mikiReceiver).mikiReceive(_srcChainId, sender, receiver, _token, _amountLD, message, id);
        }
    }

    function receiveMsg(uint256 _srcChainId, address _srcAddress, bytes memory _payload) external {
        (address sender, address receiver, bytes memory messageWithMikiId) =
            abi.decode(_payload, (address, address, bytes));

        (bytes32 id, bytes memory message) = abi.decode(messageWithMikiId, (bytes32, bytes));

        IMikiReceiver(mikiReceiver).mikiReceive(_srcChainId, sender, receiver, address(0), 0, message, id);
    }

    fallback() external payable { }

    receive() external payable { }
}
