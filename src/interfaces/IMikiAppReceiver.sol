// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface IMikiAppReceiver {
    function mikiReceive(
        uint256 srcChainId,
        address srcAddress,
        address token,
        uint256 amount,
        bytes calldata message
    )
        external
        payable;

    function mikiReceiveMsg(uint256 srcChainId, address srcAddress, bytes calldata message) external payable;
}
