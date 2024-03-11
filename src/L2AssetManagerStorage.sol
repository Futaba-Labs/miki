// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2AssetManager } from "./interfaces/IL2AssetManager.sol";

abstract contract L2AssetManagerStorage is IL2AssetManager {
    address public nativeTokenPool;
    mapping(address tokenPool => mapping(address user => uint256 balance)) public balances;
    mapping(address user => address[] tokenPools) public userTokenPools;
    mapping(address tokenPool => bool) public tokenPoolisWhitelisted;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[39] private __gap;
}
