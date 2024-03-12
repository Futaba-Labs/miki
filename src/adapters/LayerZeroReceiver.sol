// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IStargateReceiver } from "../interfaces/IStargateReceiver.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LayerZeroReceiver is IStargateReceiver {
    using Address for address;
    /* ----------------------------- Storage -------------------------------- */

    address public immutable stargateRouter;

    /* ----------------------------- Events -------------------------------- */

    event ReceiveSuceess(uint16 _srcChainId, address _srcAddress, address _token, address _receiver, uint256 _amountLD);
    event FallbackReceived(address indexed sender, uint256 value, string message);
    event Received(address indexed sender, uint256 value, string message);

    /* ----------------------------- Erorrs -------------------------------- */

    error InvalidRouter();
    error InvalidCall(bytes data);

    /* ----------------------------- Constructor -------------------------------- */
    constructor(address _stargateRouter) {
        stargateRouter = _stargateRouter;
    }

    fallback() external payable {
        emit FallbackReceived(msg.sender, msg.value, "Fallback was called");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value, "Receive was called");
    }

    /**
     * @param _srcChainId - source chain identifier
     * @param _srcAddress - source address identifier
     * @param _nonce - message ordering nonce
     * @param _token - token contract
     * @param _amountLD - amount (local decimals) to recieve
     * @param _payload - bytes containing the toAddress
     */
    function sgReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 _amountLD,
        bytes memory _payload
    )
        external
        override
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
}
