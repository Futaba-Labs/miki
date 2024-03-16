// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import { IAcrossV3SpokePool } from "../interfaces/IAcrossV3SpokePool.sol";

contract L2BridgeAdapter is IL2BridgeAdapter {
    /* ----------------------------- Storage -------------------------------- */
    address public immutable spokePool;
    address public receiver;

    /* ----------------------------- Constructor -------------------------------- */
    constructor(address _spokePool) {
        spokePool = _spokePool;
    }

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
    {
        // TODO: Implement the cross chain contract call
    }

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
        uint32 quoteTimestamp = abi.decode(params, (uint32));

        bytes memory payload = abi.encodePacked(message, recipient);

        IAcrossV3SpokePool(spokePool).depositV3{ value: amount }(
            msg.sender,
            receiver,
            asset,
            address(0),
            amount,
            amount - fee,
            dstChainId,
            address(0),
            quoteTimestamp,
            uint32(block.timestamp + 21_600),
            0,
            payload
        );
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
        uint32 quoteTimestamp = abi.decode(params, (uint32));

        IAcrossV3SpokePool(spokePool).depositV3{ value: amount }(
            msg.sender,
            recipient,
            asset,
            address(0),
            amount,
            amount - fee,
            dstChainId,
            address(0),
            quoteTimestamp,
            uint32(block.timestamp + 21_600),
            0,
            ""
        );
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
        return 0;
    }
}
