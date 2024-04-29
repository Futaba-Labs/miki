// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { ITokenPool } from "../interfaces/ITokenPool.sol";
import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import { IL2AssetManager } from "../interfaces/IL2AssetManager.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract TokenPoolBase is ITokenPool, Initializable, OwnableUpgradeable {
    /* ----------------------------- Storage -------------------------------- */
    /// @notice The nonce of the token pool
    uint256 private _nonce;

    /// @notice The L2 asset manager address
    address public immutable l2AssetManager;

    /// @notice The operator address to batch
    address public immutable operator;

    /// @notice The total amount of the token pool
    uint256 public totalAmount;

    /// @notice The underlying token address
    address public underlyingToken;

    /// @notice Mapping: dstChainId => bridgeAdapter
    mapping(uint256 dstChainId => address bridgeAdapter) public bridgeAdapters;

    /// @notice The batches
    BatchInfo[] public batches;

    /* ----------------------------- Struct -------------------------------- */
    /// @notice The batch info
    struct BatchInfo {
        address user;
        uint256 amount;
    }

    /* ----------------------------- Constructor -------------------------------- */
    /**
     * @notice Constructor
     * @param _l2AssetManager The L2 asset manager address
     * @param _operator The operator address to batch
     */
    constructor(address _l2AssetManager, address _operator) {
        l2AssetManager = _l2AssetManager;
        operator = _operator;
        _disableInitializers();
    }

    /* ----------------------------- Initializer -------------------------------- */
    /**
     * @notice Initialize the token pool
     * @param _initialOwner The initial owner address
     * @param _underlyingToken The underlying token address
     */
    function initialize(address _initialOwner, address _underlyingToken) public virtual initializer {
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

    /**
     * @notice Get the total amount of the token pool
     * @return The total amount of the token pool
     */
    function getTotalAmount() external view returns (uint256) {
        return totalAmount;
    }

    function getUnderlyingToken() external view returns (address) {
        return underlyingToken;
    }

    /**
     * @notice Get the batches
     * @return The batches
     */
    function getBatches() external view returns (BatchInfo[] memory) {
        return batches;
    }

    /**
     * @notice Set the bridge adapter
     * @dev Reverts if the address is zero
     * @param dstChainId The destination chain id
     * @param bridgeAdapter The bridge adapter address
     */
    function setBridgeAdapter(uint256 dstChainId, address bridgeAdapter) external onlyOwner {
        if (bridgeAdapter == address(0)) {
            revert ZeroAddress();
        }
        bridgeAdapters[dstChainId] = bridgeAdapter;
        emit SetBridgeAdapter(dstChainId, bridgeAdapter);
    }

    /**
     * @notice Get the bridge adapter
     * @param dstChainId The destination chain id
     * @return The bridge adapter address
     */
    function getBridgeAdapter(uint256 dstChainId) external view returns (address) {
        return bridgeAdapters[dstChainId];
    }

    /**
     * @notice Add the batches
     * @param user The user address
     * @param amount The amount of the asset
     */
    function addBatches(address user, uint256 amount) external onlyL2AssetManager {
        batches.push(BatchInfo(user, amount));
        emit AddBatch(user, amount);
    }

    /* ----------------------------- Internal Functions -------------------------------- */
    /**
     * @notice Logic called before bridging assets
     * @dev Reverts if the bridge adapter is not set
     * @dev Reverts if the user does not have enough balance
     * @dev Reverts if the fee is less than the estimated fee
     * @param user The user address
     * @param dstChainId The destination chain id
     * @param receipient The recipient address
     * @param fee The fee of the cross chain contract call
     * @param amount The amount of the asset
     * @param data The message of the cross chain contract call
     * @param bridgeAdapter The bridge adapter address
     * @param params The params of the cross chain contract call
     */
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

    /**
     * @notice Logic called after bridging assets
     * @dev Reduce the amount of assets used from L2AssetManager
     * @dev Increment the nonce
     * @param user The user address
     * @param amount The amount of the asset
     */
    function _afterBridge(address user, uint256 amount) internal virtual {
        IL2AssetManager(l2AssetManager).removeDeposits(address(this), user, amount);
        ++_nonce;
    }

    /**
     * @notice Extract the id from the information in the bridge
     * @param sender The sender address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param data The message of the cross chain contract call
     * @return The unique id
     */
    function _extractId(
        address sender,
        uint256 dstChainId,
        address recipient,
        bytes memory data
    )
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_nonce, sender, dstChainId, recipient, data));
    }

    /**
     * @notice Build the payload of the bridge
     * @param id The unique id
     * @param data The message of the cross chain contract call
     * @return The payload of the bridge
     */
    function _buildPayload(bytes32 id, bytes memory data) internal pure returns (bytes memory) {
        return abi.encode(id, data);
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
