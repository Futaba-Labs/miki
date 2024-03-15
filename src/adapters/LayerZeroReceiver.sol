// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IStargateReceiver } from "../interfaces/IStargateReceiver.sol";
import { ILayerZeroReceiver } from "../interfaces/ILayerZeroReceiver.sol";
import { ILayerZeroComposer } from "../interfaces/ILayerZeroComposer.sol";
import { OApp } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LayerZeroReceiver is IStargateReceiver, ILayerZeroReceiver, ILayerZeroComposer {
    using Address for address;
    /* ----------------------------- Storage -------------------------------- */

    address public immutable stargateRouter;

    /* ----------------------------- Events -------------------------------- */
    event ExecutedFunctionCall(address sender, address receiver, bytes encodedSelector, bytes data);
    event ReceiveSuceess(uint16 _srcChainId, address _srcAddress, address _token, address _receiver, uint256 _amountLD);

    /* ----------------------------- Erorrs -------------------------------- */

    error InvalidRouter();
    error InvalidCall(bytes data);

    /* ----------------------------- Constructor -------------------------------- */
    constructor(address _stargateRouter) {
        stargateRouter = _stargateRouter;
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
        if (msg.sender != stargateRouter) {
            revert InvalidRouter();
        }

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

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    )
        external
    {
        // Decode the payload
        (address sender, address receiver, bytes memory encodedSelector) =
            abi.decode(_payload, (address, address, bytes));

        // Call the receiver
        bytes memory data = receiver.functionCall(encodedSelector);

        emit ExecutedFunctionCall(sender, receiver, encodedSelector, data);
    }

    function lzCompose(
        address _oApp,
        bytes32, /*_guid*/
        bytes calldata _message,
        address,
        bytes calldata
    )
        external
        payable
        override
    {
        (uint64 nonce, uint32 srcEid, uint256 amountLD, bytes memory composeMsg) =
            abi.decode(_message, (uint64, uint32, uint256, bytes));
        (address sender, address receiver, bytes memory encodedSelector) =
            abi.decode(composeMsg, (address, address, bytes));

        IERC20(_oApp).approve(receiver, amountLD);
        receiver.functionCall(encodedSelector);
        (encodedSelector);
    }

    fallback() external payable { }

    receive() external payable { }
}
