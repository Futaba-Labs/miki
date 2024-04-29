// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

/**
 * @title ITokenPool
 * @notice This contract is the interface for the TokenPool contract
 */
interface ITokenPool {
    /* ----------------------------- Events -------------------------------- */
    /**
     * @notice Event emitted when a cross chain contract call is made
     * @param id The id of the cross chain contract call
     * @param sender The sender of the cross chain contract call
     * @param dstChainId The destination chain id
     * @param recipient The recipient of the cross chain contract call
     * @param data The message of the cross chain contract call
     * @param fee The fee of the cross chain contract call
     */
    event CrossChainContractCall(
        bytes32 id, address sender, uint256 dstChainId, address recipient, bytes data, uint256 fee
    );

    /**
     * @notice Event emitted when a cross chain contract call with asset is made
     * @param id The id of the cross chain contract call
     * @param sender The sender of the cross chain contract call
     * @param dstChainId The destination chain id
     * @param recipient The recipient of the cross chain contract call
     * @param data The message of the cross chain contract call
     * @param fee The fee of the cross chain contract call
     * @param amount The amount of the asset
     */
    event CrossChainContractCallWithAsset(
        bytes32 id,
        address sender,
        uint256 dstChainId,
        address recipient,
        bytes data,
        address asset,
        uint256 fee,
        uint256 amount
    );

    /**
     * @notice Event emitted when a cross chain transfer asset is made
     * @param id The id of the cross chain transfer asset
     * @param sender The sender of the cross chain transfer asset
     * @param dstChainId The destination chain id
     * @param recipient The recipient of the cross chain transfer asset
     * @param asset The asset to transfer
     * @param fee The fee of the cross chain transfer asset
     * @param amount The amount of the asset
     */
    event CrossChainTransferAsset(
        bytes32 id, address sender, uint256 dstChainId, address recipient, address asset, uint256 fee, uint256 amount
    );

    /**
     * @notice Event emitted when the bridge adapter is set
     * @param dstChainId The destination chain id
     * @param bridgeAdapter The bridge adapter address
     */
    event SetBridgeAdapter(uint256 dstChainId, address bridgeAdapter);

    /**
     * @notice Event emitted when batches are added
     * @param user The user address
     * @param amount The amount of the batches
     */
    event AddBatch(address user, uint256 amount);

    /* ----------------------------- Erorrs -------------------------------- */

    /// @notice Only the L2 asset manager can call this function
    error OnlyL2AssetManager();

    /// @notice Only the operator can call this function
    error OnlyOperator();

    /// @notice The address is zero
    error ZeroAddress();

    /// @notice The chain is not supported
    error NotSupportedChain();

    /// @notice The fee is insufficient
    error InsufficientFee();

    /// @notice The transfer is invalid
    error InvalidTransfer();

    /// @notice The amount is insufficient
    error InsufficientAmount();

    /* ----------------------------- Functions -------------------------------- */

    /**
     * @notice Deposit the amount to the token pool
     * @param amount The amount to deposit
     */
    function deposit(uint256 amount) external payable;

    /**
     * @notice Withdraw the amount from the token pool
     * @param user The user address
     * @param amount The amount to withdraw
     */
    function withdraw(address user, uint256 amount) external;

    /**
     * @notice Make a cross chain contract call
     * @param dstChainId The destination chain id
     * @param recipient The recipient of the cross chain contract call
     * @param data The message of the cross chain contract call
     * @param fee The fee of the cross chain contract call
     * @param params The params of the cross chain contract call
     */
    function crossChainContractCall(
        uint256 dstChainId,
        address recipient,
        bytes calldata data,
        uint256 fee,
        bytes calldata params
    )
        external
        payable;

    /**
     * @notice Make a cross chain contract call with asset
     * @param dstChainId The destination chain id
     * @param recipient The recipient of the cross chain contract call
     * @param data The message of the cross chain contract call
     * @param fee The fee of the cross chain contract call
     * @param amount The amount of the asset
     * @param params The params of the cross chain contract call
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
        payable;

    /**
     * @notice Make a cross chain transfer asset
     * @param dstChainId The destination chain id
     * @param recipient The recipient of the cross chain transfer asset
     * @param fee The fee of the cross chain transfer asset
     * @param amount The amount of the asset
     * @param params The params of the cross chain transfer asset
     */
    function crossChainTransferAsset(
        uint256 dstChainId,
        address recipient,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable;

    /**
     * @notice Make a cross chain contract call with asset to L1
     * @param fee The fee of the cross chain contract call
     * @param params The params of the cross chain contract call
     */
    function crossChainContractCallWithAssetToL1(uint256 fee, bytes calldata params) external payable;

    /**
     * @notice Get the total amount of the token pool
     * @return The total amount of the token pool
     */
    function getTotalAmount() external view returns (uint256);

    /**
     * @notice Get the underlying token address
     * @return The underlying token address
     */
    function getUnderlyingToken() external view returns (address);

    /**
     * @notice Set the bridge adapter
     * @param dstChainId The destination chain id
     * @param bridgeAdapter The bridge adapter address
     */
    function setBridgeAdapter(uint256 dstChainId, address bridgeAdapter) external;

    /**
     * @notice Get the bridge adapter
     * @param dstChainId The destination chain id
     * @return The bridge adapter address
     */
    function getBridgeAdapter(uint256 dstChainId) external view returns (address);

    /**
     * @notice Add batches to the token pool
     * @param user The user address
     * @param amount The amount of the batches
     */
    function addBatches(address user, uint256 amount) external;
}
