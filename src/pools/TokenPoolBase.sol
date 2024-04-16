// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { ITokenPool } from "../interfaces/ITokenPool.sol";
import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import { IL2AssetManager } from "../interfaces/IL2AssetManager.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract TokenPoolBase is ITokenPool, Initializable, OwnableUpgradeable {
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
    constructor(address _l2AssetManager, address _underlyingToken, address _operator) {
        l2AssetManager = _l2AssetManager;
        operator = _operator;
        underlyingToken = _underlyingToken;
    }

    /* ----------------------------- Initializer -------------------------------- */

    function initialize(address _initialOwner, address _underlyingToken) public virtual initializer {
        _initializeTokenPoolBase(_initialOwner, _underlyingToken);
    }

    function _initializeTokenPoolBase(address _initialOwner, address _underlyingToken) internal onlyInitializing {
        __Ownable_init(_initialOwner);
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

    function deposit(uint256 amount) external payable virtual;

    function withdraw(address user, uint256 amount) external virtual;

    function crossChainContractCall(
        uint256 dstChainId,
        address recipient,
        bytes calldata data,
        uint256 fee,
        bytes calldata params
    )
        external
        payable
        virtual;

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
        virtual;

    function crossChainTransferAsset(
        uint256 dstChainId,
        address recipient,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable
        virtual;

    function crossChainContractCallWithAssetToL1(uint256 fee, bytes calldata params) external payable virtual;

    function getTotalAmount() external view returns (uint256) {
        return totalAmount;
    }

    function getUnderlyingToken() external view returns (address) {
        return underlyingToken;
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
        address receipient,
        uint256 fee,
        uint256 amount,
        bytes memory data,
        IL2BridgeAdapter bridgeAdapter,
        bytes memory params
    )
        internal
        virtual
    {
        if (bridgeAdapters[dstChainId] == address(0)) {
            revert NotSupportedChain();
        }

        uint256 balance = IL2AssetManager(l2AssetManager).getDeposit(address(this), user);
        if (balance < fee + amount) {
            revert InsufficientAmount();
        }

        uint256 estimatedFee =
            bridgeAdapter.estimateFee(user, dstChainId, receipient, underlyingToken, data, amount, params);
        if (fee < estimatedFee) {
            revert InsufficientFee();
        }
    }

    function _afterBridge(address user, uint256 amount) internal virtual {
        IL2AssetManager(l2AssetManager).removeDeposits(address(this), user, amount);
    }

    fallback() external payable { }

    receive() external payable { }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
