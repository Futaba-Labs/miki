// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2AssetManager } from "./interfaces/IL2AssetManager.sol";

/**
 * @title L2AssetManagerStorage
 * @notice This contract holds the storage for the L2AssetManager contract
 */
abstract contract L2AssetManagerStorage is IL2AssetManager {
    /// @notice The address of the native token pool
    address public nativeTokenPool;

    /// @notice Mapping: token pool  => user => balance
    mapping(address tokenPool => mapping(address user => uint256 balance)) public balances;

    /// @notice Mapping: user => token pools deposited by user
    mapping(address user => address[] tokenPools) public userTokenPools;

    /// @notice Mapping: token pool => is whitelisted
    mapping(address tokenPool => bool isWhitelisted) public tokenPoolisWhitelisted;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[39] private __gap;
}
