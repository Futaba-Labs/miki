// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2BridgeAdapter } from "../../src/interfaces/IL2BridgeAdapter.sol";

contract BridgeAdapterMock is IL2BridgeAdapter {
    function execCrossChainContractCall(
        uint256 dstChainId,
        address recipient,
        bytes calldata message,
        uint256 fee
    )
        external
        payable
    { }

    function execCrossChainContractCallWithAsset(
        uint256 dstChainId,
        address recipient,
        bytes calldata message,
        uint256 fee,
        uint256 amount
    )
        external
        payable
    { }

    function execCrossChainTransferAsset(
        uint256 dstChainId,
        address recipient,
        uint256 fee,
        uint256 amount
    )
        external
        payable
    { }

    function estimateFee(uint256 dstChainId, bytes calldata message) external view returns (uint256) {
        return 10_000;
    }
}
