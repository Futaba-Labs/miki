// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface ISampleAMM {
    function swap(address _tokenIn, uint256 _amountIn) external returns (uint256 amountOut);
}
