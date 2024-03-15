// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IStargateReceiver } from "../interfaces/IStargateReceiver.sol";
import { ILayerZeroReceiver } from "../interfaces/ILayerZeroReceiver.sol";
import { IOAppComposer } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppComposer.sol";
import { OApp } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { OFTComposeMsgCodec } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMikiReceiver } from "../interfaces/IMikiReceiver.sol";

contract LayerZeroReceiver is IStargateReceiver, ILayerZeroReceiver, IOAppComposer {
    using Address for address;
    using OFTComposeMsgCodec for bytes;
    /* ----------------------------- Storage -------------------------------- */

    address public immutable stargateRouter;
    mapping(uint32 => uint256) public chainIdOf;

    /* ----------------------------- Events -------------------------------- */
    event ExecutedFunctionCall(address sender, address receiver, bytes encodedSelector, bytes data);
    event SentMsgAndToken(
        uint256 _srcChainId, address _srcAddress, address _token, address _receiver, uint256 _amountLD, bytes _message
    );

    event FailedMsgAndToken(
        uint256 _srcChainId,
        address _srcAddress,
        address _token,
        address _receiver,
        uint256 _amountLD,
        bytes _message,
        string _reason
    );

    /* ----------------------------- Erorrs -------------------------------- */

    error InvalidRouter();
    error InvalidCall(bytes data);
    error MismatchLength();
    error InvalidLength();
    error TransferFailed();

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
        address _from,
        bytes32,
        bytes calldata _message,
        address,
        bytes calldata /*_extraData*/
    )
        external
        payable
    {
        uint32 srcEid = _message.srcEid();
        uint256 amountLD = _message.amountLD();
        bytes memory composeMsg = _message.composeMsg();
        (address sender, address receiver, bytes memory message) = abi.decode(composeMsg, (address, address, bytes));

        bool success = IERC20(_from).transfer(receiver, amountLD);
        if (!success) {
            revert TransferFailed();
        }

        uint256 chainId = chainIdOf[srcEid];

        try IMikiReceiver(receiver).mikiReceive(chainId, sender, _from, amountLD, message) {
            emit SentMsgAndToken(chainId, sender, _from, receiver, amountLD, message);
        } catch Error(string memory reason) {
            emit FailedMsgAndToken(chainId, sender, _from, receiver, amountLD, message, reason);
        } catch {
            emit FailedMsgAndToken(chainId, sender, _from, receiver, amountLD, message, "Unknown error");
        }
    }

    function setChainIds(uint32[] calldata _eids, uint256[] calldata _chainIds) external {
        uint256 eidsLen = _eids.length;
        uint256 chainIdsLen = _chainIds.length;

        if (eidsLen == 0 || chainIdsLen == 0) revert InvalidLength();

        if (eidsLen != chainIdsLen) revert MismatchLength();

        for (uint256 i; i < eidsLen; i++) {
            chainIdOf[_eids[i]] = _chainIds[i];
        }
    }

    fallback() external payable { }

    receive() external payable { }
}
