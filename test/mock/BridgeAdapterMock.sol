// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2BridgeAdapter } from "../../src/interfaces/IL2BridgeAdapter.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BridgeAdapterMock is IL2BridgeAdapter {
    using SafeERC20 for IERC20;

    function execCrossChainContractCall(
        address sender,
        uint256 dstChainId,
        address recipient,
        bytes calldata message,
        uint256 fee,
        bytes calldata params
    )
        external
        payable
    { }

    function execCrossChainContractCallWithAsset(
        address sender,
        uint256 dstChainId,
        address recipient,
        address asset,
        bytes calldata message,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable
    {
        (bool isNative) = abi.decode(params, (bool));
        if (!isNative) {
            IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
            IERC20(asset).approve(address(this), amount);
        }
    }

    function execCrossChainTransferAsset(
        address sender,
        uint256 dstChainId,
        address recipient,
        address asset,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable
    {
        (bool isNative) = abi.decode(params, (bool));
        if (!isNative) {
            IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
            IERC20(asset).approve(address(this), amount);
        }
    }

    function estimateFee(
        address sender,
        uint256 dstChainId,
        address recipient,
        address asset,
        bytes calldata message,
        uint256 amount,
        bytes calldata params
    )
        external
        view
        returns (uint256)
    {
        return 10_000;
    }
}
