// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface ICCTPReceiver {
    // @notice CCTP endpoint will invoke this function to deliver the message on the destination
    // @param _message - the message to be validated by MessageTransmitter
    // @param _attestation - the attestation to be validated by MessageTransmitter
    // @param _recipient - the final recipient of tokens
    // @param _srcChainId - the source chain id for MikiReceiver
    // @param _srcAddress - the source address for MikiReceiver
    function cctpReceive(
        bytes calldata _message,
        bytes calldata _attestation,
        address _recipient,
        uint256 _srcChainId,
        address _srcAddress
    )
        external;
}
