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
    mapping(uint256 dstChainId => address bridgeAdapter) public bridgeAdapters;
    BatchInfo[] public batches;

    /* ----------------------------- Struct -------------------------------- */
    struct BatchInfo {
        address user;
        uint256 amount;
    }

    /* ----------------------------- Constructor -------------------------------- */
    constructor(address _initialOwner, address _l2AssetManager, address _operator) Ownable(_initialOwner) {
        l2AssetManager = _l2AssetManager;
        operator = _operator;
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
        uint256 fee
    )
        external
        payable
    {
        IL2BridgeAdapter bridgeAdapter = IL2BridgeAdapter(bridgeAdapters[dstChainId]);

        _beforeBridge(dstChainId, fee, data, bridgeAdapter);

        bridgeAdapter.execCrossChainContractCall{ value: fee }(dstChainId, recipient, data, fee);
        IL2AssetManager(l2AssetManager).removeDeposits(address(this), msg.sender, fee);

        emit CrossChainContractCall(msg.sender, dstChainId, recipient, data, fee);
    }

    function crossChainContractCallWithAsset(
        uint256 dstChainId,
        address recipient,
        bytes calldata data,
        uint256 fee,
        uint256 amount
    )
        external
        payable
    {
        IL2BridgeAdapter bridgeAdapter = IL2BridgeAdapter(bridgeAdapters[dstChainId]);

        _beforeBridge(dstChainId, fee, data, bridgeAdapter);

        bridgeAdapter.execCrossChainContractCallWithAsset{ value: fee }(dstChainId, recipient, data, fee, amount);
        IL2AssetManager(l2AssetManager).removeDeposits(address(this), msg.sender, fee + amount);
        emit CrossChainContractCallWithAsset(msg.sender, dstChainId, recipient, data, fee, amount);
    }

    function crossChainTransferAsset(
        uint256 dstChainId,
        address recipient,
        uint256 fee,
        uint256 amount
    )
        external
        payable
    {
        IL2BridgeAdapter bridgeAdapter = IL2BridgeAdapter(bridgeAdapters[dstChainId]);

        _beforeBridge(dstChainId, fee, bytes(""), bridgeAdapter);

        bridgeAdapter.execCrossChainTransferAsset{ value: fee }(dstChainId, recipient, fee, amount);
        IL2AssetManager(l2AssetManager).removeDeposits(address(this), msg.sender, fee + amount);
        emit CrossChainTransferAsset(msg.sender, dstChainId, recipient, amount);
    }

    function crossChainContractCallWithAssetToL1(uint256 fee) external payable onlyOperator {
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
    }

    /* ----------------------------- Internal Functions -------------------------------- */
    function _beforeBridge(
        uint256 dstChainId,
        uint256 fee,
        bytes memory data,
        IL2BridgeAdapter bridgeAdapter
    )
        internal
        view
    {
        if (bridgeAdapters[dstChainId] == address(0)) {
            revert NotSupportedChain();
        }

        uint256 estimatedFee = bridgeAdapter.estimateFee(dstChainId, data);
        if (fee < estimatedFee) {
            revert InsufficientFee();
        }
    }
}
