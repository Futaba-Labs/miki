// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseTokenPool } from "../../src/pools/BaseTokenPool.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IL2BridgeAdapter } from "../../src/interfaces/IL2BridgeAdapter.sol";
import { IL2AssetManager } from "../../src/interfaces/IL2AssetManager.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC20TokenPoolMock is BaseTokenPool {
    using SafeERC20 for IERC20;
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
        if (amount <= 0) revert InsufficientAmount();
        totalAmount += amount;
    }

    function withdraw(address user, uint256 amount) external override onlyL2AssetManager {
        if (amount <= 0) revert InsufficientAmount();
        totalAmount -= amount;
        IERC20(underlyingToken).safeTransfer(user, amount);
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
    { }

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

        bridgeAdapter.execCrossChainContractCallWithAsset{ value: fee }(
            user, dstChainId, recipient, underlyingToken, data, fee, amount, params
        );

        _afterBridge(user, amount);
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

        bridgeAdapter.execCrossChainTransferAsset{ value: fee }(
            user, dstChainId, recipient, underlyingToken, fee, amount, params
        );

        _afterBridge(user, amount);
        emit CrossChainTransferAsset(user, dstChainId, recipient, amount);
    }

    function _beforeBridge(
        address user,
        uint256 dstChainId,
        address recipient,
        uint256 fee,
        uint256 amount,
        bytes memory data,
        IL2BridgeAdapter bridgeAdapter,
        bytes memory params
    )
        internal
        view
        override
    {
        if (address(bridgeAdapter) == address(0)) {
            revert NotSupportedChain();
        }

        uint256 balance = IL2AssetManager(l2AssetManager).getDeposit(address(this), user);
        if (balance < amount) {
            revert InsufficientAmount();
        }

        uint256 estimatedFee =
            bridgeAdapter.estimateFee(user, dstChainId, recipient, underlyingToken, data, amount, params);
        if (fee < estimatedFee) {
            revert InsufficientFee();
        }
    }
}
