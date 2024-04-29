// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import { IL2AssetManager } from "../interfaces/IL2AssetManager.sol";
import { TokenPoolBase } from "./TokenPoolBase.sol";

contract ETHTokenPool is TokenPoolBase {
    /* ----------------------------- Constructor -------------------------------- */
    constructor(address _l2AssetManager, address _operator) TokenPoolBase(_l2AssetManager, _operator) { }

    /* ----------------------------- External Functions -------------------------------- */

    /**
     * @notice Deposit the amount of ETH to the token pool
     * @dev Reverts if the amount is less than or equal to 0
     * @param amount The amount of ETH to deposit
     */
    function deposit(uint256 amount) external payable override onlyL2AssetManager {
        if (msg.value <= 0) revert InsufficientAmount();
        totalAmount += amount;
    }

    /**
     * @notice Withdraw the amount of ETH from the token pool
     * @dev Reverts if the amount is less than or equal to 0
     * @param user The user address
     * @param amount The amount of ETH to withdraw
     */
    function withdraw(address user, uint256 amount) external override onlyL2AssetManager {
        if (amount <= 0) revert InsufficientAmount();
        totalAmount -= amount;
        (bool success,) = payable(user).call{ value: amount }("");
        if (!success) revert InvalidTransfer();
    }

    /**
     * @notice Make a cross chain contract call
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param data The message of the cross chain contract call
     * @param fee The fee of the cross chain contract call
     * @param params The parameters of the cross chain contract call
     */
    function crossChainContractCall(
        uint256 dstChainId,
        address recipient,
        bytes calldata data,
        uint256 fee,
        bytes calldata params
    )
        external
        payable
        override
    {
        _crossChainContractCall(msg.sender, dstChainId, recipient, data, fee, params);
    }

    /**
     * @notice Make a cross chain contract call with asset
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param data The message of the cross chain contract call
     * @param fee The fee of the cross chain contract call
     * @param amount The amount of the asset
     * @param params The parameters of the cross chain contract call
     */
    function crossChainContractCallWithAsset(
        uint256 dstChainId,
        address recipient,
        bytes calldata data,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable
        override
    {
        _crossChainContractCallWithAsset(msg.sender, dstChainId, recipient, data, fee, amount, params);
    }

    /**
     * @notice Make a cross chain transfer asset
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param fee The fee of the cross chain transfer asset
     * @param amount The amount of the asset
     * @param params The parameters of the cross chain transfer asset
     */
    function crossChainTransferAsset(
        uint256 dstChainId,
        address recipient,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable
        override
    {
        _crossChainTransferAsset(msg.sender, dstChainId, recipient, fee, amount, params);
    }

    function crossChainContractCallWithAssetToL1(uint256 fee, bytes calldata params) external payable { }

    /* ----------------------------- Internal Functions -------------------------------- */

    /**
     * @notice Make a cross chain contract call
     * @param user The user address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param data The message of the cross chain contract call
     * @param fee The fee of the cross chain contract call
     * @param params The parameters of the cross chain contract call
     */
    function _crossChainContractCall(
        address user,
        uint256 dstChainId,
        address recipient,
        bytes calldata data,
        uint256 fee,
        bytes calldata params
    )
        internal
    {
        IL2BridgeAdapter bridgeAdapter = IL2BridgeAdapter(bridgeAdapters[dstChainId]);

        _beforeBridge(user, dstChainId, recipient, fee, 0, data, bridgeAdapter, params);
        bytes32 id = _extractId(user, dstChainId, recipient, data);
        bytes memory payload = _buildPayload(id, data);
        bridgeAdapter.execCrossChainContractCall{ value: fee }(user, dstChainId, recipient, payload, fee, params);

        _afterBridge(user, fee);

        emit CrossChainContractCall(id, user, dstChainId, recipient, data, fee);
    }

    /**
     * @notice Make a cross chain contract call with asset
     * @param user The user address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param data The message of the cross chain contract call
     * @param fee The fee of the cross chain contract call
     * @param amount The amount of the asset
     * @param params The parameters of the cross chain contract call
     */
    function _crossChainContractCallWithAsset(
        address user,
        uint256 dstChainId,
        address recipient,
        bytes calldata data,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        internal
    {
        IL2BridgeAdapter bridgeAdapter = IL2BridgeAdapter(bridgeAdapters[dstChainId]);

        _beforeBridge(user, dstChainId, recipient, fee, amount, data, bridgeAdapter, params);

        uint256 total = fee + amount;
        bytes32 id = _extractId(user, dstChainId, recipient, data);
        bytes memory payload = _buildPayload(id, data);

        bridgeAdapter.execCrossChainContractCallWithAsset{ value: total }(
            user, dstChainId, recipient, underlyingToken, payload, fee, amount, params
        );

        _afterBridge(user, total);

        emit CrossChainContractCallWithAsset(id, user, dstChainId, recipient, data, underlyingToken, fee, amount);
    }

    /**
     * @notice Make a cross chain transfer asset
     * @param user The user address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param fee The fee of the cross chain transfer asset
     * @param amount The amount of the asset
     * @param params The parameters of the cross chain transfer asset
     */
    function _crossChainTransferAsset(
        address user,
        uint256 dstChainId,
        address recipient,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        internal
    {
        IL2BridgeAdapter bridgeAdapter = IL2BridgeAdapter(bridgeAdapters[dstChainId]);

        _beforeBridge(user, dstChainId, recipient, fee, amount, bytes(""), bridgeAdapter, params);

        uint256 total = fee + amount;

        bridgeAdapter.execCrossChainTransferAsset{ value: total }(
            user, dstChainId, recipient, underlyingToken, fee, amount, params
        );

        _afterBridge(user, total);
        bytes32 id = _extractId(user, dstChainId, recipient, bytes(""));

        emit CrossChainTransferAsset(id, user, dstChainId, recipient, underlyingToken, fee, amount);
    }
}
