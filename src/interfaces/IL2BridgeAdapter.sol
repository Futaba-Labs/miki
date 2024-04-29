// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

/**
 * @title IL2BridgeAdapter
 * @notice This interface is used to interact with the L2BridgeAdapter
 */
interface IL2BridgeAdapter {
    /**
     * @notice Execute a cross chain contract call
     * @param sender The sender address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param message The message of the cross chain contract call
     * @param fee The fee of the cross chain contract call
     * @param params The parameters of the cross chain contract call
     */
    function execCrossChainContractCall(
        address sender,
        uint256 dstChainId,
        address recipient,
        bytes calldata message,
        uint256 fee,
        bytes calldata params
    )
        external
        payable;

    /**
     * @notice Execute a cross chain contract call with asset
     * @param sender The sender address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param asset The asset address
     * @param message The message of the cross chain contract call
     * @param fee The fee of the cross chain contract call
     * @param amount The amount of the asset
     * @param params The parameters of the cross chain contract call
     */
    function execCrossChainContractCallWithAsset(
        address sender,
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

    /**
     * @notice Execute a cross chain transfer asset
     * @param sender The sender address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param asset The asset address
     * @param fee The fee of the cross chain transfer asset
     * @param amount The amount of the asset
     * @param params The parameters of the cross chain transfer asset
     */
    function execCrossChainTransferAsset(
        address sender,
        uint256 dstChainId,
        address recipient,
        address asset,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable;

    /**
     * @notice Estimate the fee of a cross chain contract call
     * @param sender The sender address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param asset The asset address
     * @param message The message of the cross chain contract call
     * @param amount The amount of the asset
     * @param params The parameters of the cross chain contract call
     */
    function estimateFee(
        address sender,
        uint256 dstChainId,
        address recipient,
        address asset,
        bytes calldata message,
        uint256 amount,
        bytes calldata params
    )
        external
        view
        returns (uint256);
}
