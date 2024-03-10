// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";

contract AcrossBridgeAdapter is IL2BridgeAdapter {
    function execCrossChainContractCall(
        uint256 dstChainId,
        address recipient,
        bytes calldata message,
        uint256 fee
    )
        external
        payable
    {
        // TODO: Implement the cross chain contract call
    }

    function execCrossChainContractCallWithAsset(
        uint256 dstChainId,
        address recipient,
        bytes calldata message,
        uint256 fee,
        uint256 amount
    )
        external
        payable
    {
        // TODO: Implement the cross chain contract call with asset
    }

    function execCrossChainTransferAsset(
        uint256 dstChainId,
        address recipient,
        uint256 fee,
        uint256 amount
    )
        external
        payable
    {
        // TODO: Implement the cross chain transfer asset
    }

    function estimateFee(uint256 dstChainId, bytes calldata message) external view returns (uint256) {
        return 0;
    }
}
