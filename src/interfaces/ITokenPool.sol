// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface ITokenPool {
    /* ----------------------------- Events -------------------------------- */
    event CrossChainContractCall(
        bytes32 id, address sender, uint256 dstChainId, address recipient, bytes data, uint256 fee
    );
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
    event CrossChainTransferAsset(
        bytes32 id, address sender, uint256 dstChainId, address recipient, address asset, uint256 fee, uint256 amount
    );
    event SetBridgeAdapter(uint256 dstChainId, address bridgeAdapter);
    event AddBatch(address user, uint256 amount);
    /* ----------------------------- Erorrs -------------------------------- */

    error OnlyL2AssetManager();
    error OnlyOperator();
    error ZeroAddress();
    error NotSupportedChain();
    error InsufficientFee();
    error InvalidTransfer();
    error InsufficientAmount();
    /* ----------------------------- Functions -------------------------------- */

    function deposit(uint256 amount) external payable;
    function withdraw(address user, uint256 amount) external;
    function crossChainContractCall(
        uint256 dstChainId,
        address recipient,
        bytes calldata data,
        uint256 fee,
        bytes calldata params
    )
        external
        payable;
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
    function crossChainTransferAsset(
        uint256 dstChainId,
        address recipient,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable;
    function crossChainContractCallWithAssetToL1(uint256 fee, bytes calldata params) external payable;
    function getTotalAmount() external view returns (uint256);
    function getUnderlyingToken() external view returns (address);
    function setBridgeAdapter(uint256 dstChainId, address bridgeAdapter) external;
    function getBridgeAdapter(uint256 dstChainId) external view returns (address);
    function addBatches(address user, uint256 amount) external;
}
