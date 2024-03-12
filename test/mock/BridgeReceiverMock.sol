// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BridgeReceiverMock {
    using Address for address;

    event FallbackReceived(address indexed sender, uint256 value, string message);
    event Received(address indexed sender, uint256 value, string message);

    fallback() external payable {
        emit FallbackReceived(msg.sender, msg.value, "Fallback was called");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value, "Receive was called");
    }

    function receiveMsgWithAmount(
        uint256 _srcChainId,
        address _srcAddress,
        address _token,
        uint256 _amountLD,
        bytes memory _payload
    )
        external
    {
        (address receiver, bool isNative, bytes memory encodedSelector) = abi.decode(_payload, (address, bool, bytes));

        if (isNative) {
            receiver.call{ value: _amountLD }("");
            receiver.functionCall(encodedSelector);
            (encodedSelector);
        } else {
            IERC20(_token).transfer(receiver, _amountLD);
            receiver.functionCall(encodedSelector);
            (encodedSelector);
        }
    }

    function receiveMsg(uint256 _srcChainId, address _srcAddress, bytes memory _payload) external {
        (address receiver, bytes memory encodedSelector) = abi.decode(_payload, (address, bytes));

        receiver.functionCall(encodedSelector);
        (encodedSelector);
    }
}
