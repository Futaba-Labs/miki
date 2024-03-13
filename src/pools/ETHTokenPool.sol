// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { ITokenPool } from "../interfaces/ITokenPool.sol";
import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import { IL2AssetManager } from "../interfaces/IL2AssetManager.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract ETHTokenPool is ITokenPool, Ownable {
    /* ----------------------------- Storage -------------------------------- */
    address public immutable l2AssetManager;
    address public immutable operator;
    uint256 public totalAmount;
    address public underlyingToken;
    mapping(uint256 dstChainId => address bridgeAdapter) public bridgeAdapters;
    BatchInfo[] public batches;

    /* ----------------------------- Struct -------------------------------- */
    struct BatchInfo {
        address user;
        uint256 amount;
    }

    /* ----------------------------- Constructor -------------------------------- */
    constructor(
        address _initialOwner,
        address _l2AssetManager,
        address _underlyingToken,
        address _operator
    )
        Ownable(_initialOwner)
    {
        l2AssetManager = _l2AssetManager;
        operator = _operator;
        underlyingToken = _underlyingToken;
    }

    /* ----------------------------- Modifier -------------------------------- */

    modifier onlyL2AssetManager() {
        if (msg.sender != l2AssetManager) revert OnlyL2AssetManager();
        _;
    }

    modifier onlyOperator() {
        if (msg.sender != operator) revert OnlyOperator();
        _;
    }

    /* ----------------------------- External Functions -------------------------------- */

    function deposit(uint256 amount) external payable onlyL2AssetManager {
        if (msg.value <= 0) revert InsufficientAmount();
        totalAmount += amount;
    }

    function withdraw(address user, uint256 amount) external onlyL2AssetManager {
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
    {
        _crossChainTransferAsset(msg.sender, dstChainId, recipient, fee, amount, params);
    }

    function crossChainContractCallWithAssetToL1(uint256 fee, bytes calldata params) external payable onlyOperator {
        // TODO: Call the cross chain contract
    }

    function getTotalAmount() external view returns (uint256) {
        return totalAmount;
    }

    function getBatches() external view returns (BatchInfo[] memory) {
        return batches;
    }

    function setBridgeAdapter(uint256 dstChainId, address bridgeAdapter) external onlyOwner {
        if (bridgeAdapter == address(0)) {
            revert ZeroAddress();
        }
        bridgeAdapters[dstChainId] = bridgeAdapter;
        emit SetBridgeAdapter(dstChainId, bridgeAdapter);
    }

    function getBridgeAdapter(uint256 dstChainId) external view returns (address) {
        return bridgeAdapters[dstChainId];
    }

    function addBatches(address user, uint256 amount) external onlyL2AssetManager {
        batches.push(BatchInfo(user, amount));
        emit AddBatch(user, amount);
    }

    /* ----------------------------- Internal Functions -------------------------------- */
    function _beforeBridge(
        address user,
        uint256 dstChainId,
        uint256 fee,
        uint256 amount,
        bytes memory data,
        IL2BridgeAdapter bridgeAdapter,
        bytes memory params
    )
        internal
        view
    {
        if (bridgeAdapters[dstChainId] == address(0)) {
            revert NotSupportedChain();
        }

        uint256 balance = IL2AssetManager(l2AssetManager).getDeposit(address(this), user);
        if (balance < fee + amount) {
            revert InsufficientAmount();
        }

        uint256 estimatedFee = bridgeAdapter.estimateFee(dstChainId, data, params);
        if (fee < estimatedFee) {
            revert InsufficientFee();
        }
    }

    function _removeDepoits(address user, uint256 amount) internal {
        IL2AssetManager(l2AssetManager).removeDeposits(address(this), user, amount);
    }

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

        _beforeBridge(user, dstChainId, fee, 0, data, bridgeAdapter, params);

        bridgeAdapter.execCrossChainContractCall{ value: fee }(user, dstChainId, recipient, data, fee, params);

        _removeDepoits(user, fee);

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

        _beforeBridge(user, dstChainId, fee, amount, data, bridgeAdapter, params);

        uint256 total = fee + amount;
        bridgeAdapter.execCrossChainContractCallWithAsset{ value: totalAmount }(
            user, dstChainId, recipient, underlyingToken, data, fee, amount, params
        );

        _removeDepoits(user, total);
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

        _beforeBridge(user, dstChainId, fee, amount, bytes(""), bridgeAdapter, params);

        uint256 total = fee + amount;

        bridgeAdapter.execCrossChainTransferAsset{ value: totalAmount }(
            user, dstChainId, recipient, underlyingToken, fee, amount, params
        );

        _removeDepoits(user, total);
        emit CrossChainTransferAsset(user, dstChainId, recipient, amount);
    }

    fallback() external payable { }

    receive() external payable { }
}
