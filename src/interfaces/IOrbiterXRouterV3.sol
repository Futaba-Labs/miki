// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface IOrbiterXRouterV3 {
    function transfer(address to, bytes calldata data) external payable;
}
