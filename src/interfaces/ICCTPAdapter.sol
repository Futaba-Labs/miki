// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface ICCTPAdapter {
    function cctpSend(
        address sender,
        uint256 dstChainId,
        address recipient
    )
        external
        payable;
}
