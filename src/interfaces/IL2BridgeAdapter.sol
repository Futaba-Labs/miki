// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface IL2BridgeAdapter {
    function execCrossChainContractCall(
        uint256 dstChainId,
        address recipient,
        bytes calldata message,
        uint256 fee,
        bytes calldata params
    )
        external
        payable;

    function execCrossChainContractCallWithAsset(
        uint256 dstChainId,
        address recipient,
        address asset,
        bytes calldata message,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable;
    function execCrossChainTransferAsset(
        uint256 dstChainId,
        address recipient,
        address asset,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable;

    function estimateFee(
        uint256 dstChainId,
        bytes calldata message,
        bytes calldata params
    )
        external
        view
        returns (uint256);
}
