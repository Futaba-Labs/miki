// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface IOrbiterXRouterV3 {
    function transfers(address[] calldata tos, uint256[] memory values) external payable;
}
