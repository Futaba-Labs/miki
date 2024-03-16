// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import { IL2AssetManager } from "../interfaces/IL2AssetManager.sol";
import { BaseTokenPool } from "./BaseTokenPool.sol";

contract ETHTokenPool is BaseTokenPool {
    /* ----------------------------- Constructor -------------------------------- */
    constructor(
        address _initialOwner,
        address _l2AssetManager,
        address _underlyingToken,
        address _operator
    )
        BaseTokenPool(_initialOwner, _l2AssetManager, _underlyingToken, _operator)
    { }

    /* ----------------------------- External Functions -------------------------------- */

    function deposit(uint256 amount) external payable override onlyL2AssetManager {
        if (msg.value <= 0) revert InsufficientAmount();
        totalAmount += amount;
    }

    function withdraw(address user, uint256 amount) external override onlyL2AssetManager {
        if (amount <= 0) revert InsufficientAmount();
        totalAmount -= amount;
        (bool success,) = payable(user).call{ value: amount }("");
        if (!success) revert InvalidTransfer();
    }

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

    function crossChainContractCallWithAssetToL1(uint256 fee, bytes calldata params) external payable override { }

    /* ----------------------------- Internal Functions -------------------------------- */

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

        bridgeAdapter.execCrossChainContractCall{ value: fee }(user, dstChainId, recipient, data, fee, params);

        _afterBridge(user, fee);

        emit CrossChainContractCall(user, dstChainId, recipient, data, fee);
    }

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
        bridgeAdapter.execCrossChainContractCallWithAsset{ value: totalAmount }(
            user, dstChainId, recipient, underlyingToken, data, fee, amount, params
        );

        _afterBridge(user, total);
        emit CrossChainContractCallWithAsset(user, dstChainId, recipient, data, fee, amount);
    }

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

        bridgeAdapter.execCrossChainTransferAsset{ value: totalAmount }(
            user, dstChainId, recipient, underlyingToken, fee, amount, params
        );

        _afterBridge(user, total);
        emit CrossChainTransferAsset(user, dstChainId, recipient, amount);
    }
}
