// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { ETHTokenPool } from "./ETHTokenPool.sol";
import { GelatoRelayContextERC2771 } from "@gelatonetwork/relay-context/contracts/GelatoRelayContextERC2771.sol";

contract GaslessETHTokenPool is ETHTokenPool, GelatoRelayContextERC2771 {
    /* ----------------------------- Events -------------------------------- */
    event CrossChainContractCallRelay(
        bytes32 id,
        address sender,
        uint256 dstChainId,
        address recipient,
        bytes data,
        uint256 fee,
        uint256 relayFee,
        bytes params
    );

    event CrossChainContractCallWithAssetRelay(
        bytes32 id,
        address sender,
        uint256 dstChainId,
        address recipient,
        bytes data,
        address asset,
        uint256 fee,
        uint256 relayFee,
        uint256 amount,
        bytes params
    );

    event CrossChainTransferAssetRelay(
        bytes32 id,
        address sender,
        uint256 dstChainId,
        address recipient,
        address asset,
        uint256 fee,
        uint256 relayFee,
        uint256 amount,
        bytes params
    );
    /* ----------------------------- Constructor -------------------------------- */

    constructor(address _l2AssetManager, address _operator) ETHTokenPool(_l2AssetManager, _operator) { }

    /* ----------------------------- External Functions -------------------------------- */

    function crossChainContractCallRelay(
        uint256 dstChainId,
        address recipient,
        bytes calldata data,
        uint256 fee,
        bytes calldata params
    )
        external
        payable
        onlyGelatoRelayERC2771
    {
        address sender = _getMsgSender();
        _crossChainContractCall(sender, dstChainId, recipient, data, fee, params);

        _transferRelayFee();

        uint256 relayFee = _getFee();
        _afterBridge(sender, relayFee);
        bytes32 id = _extractId(sender, dstChainId, recipient, data);
        emit CrossChainContractCallRelay(id, sender, dstChainId, recipient, data, fee, relayFee, params);
    }

    function crossChainContractCallWithAssetRelay(
        uint256 dstChainId,
        address recipient,
        bytes calldata data,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable
        onlyGelatoRelayERC2771
    {
        address sender = _getMsgSender();
        _crossChainContractCallWithAsset(_getMsgSender(), dstChainId, recipient, data, fee, amount, params);

        _transferRelayFee();

        uint256 relayFee = _getFee();
        _afterBridge(sender, relayFee);
        bytes32 id = _extractId(sender, dstChainId, recipient, data);

        emit CrossChainContractCallWithAssetRelay(
            id, sender, dstChainId, recipient, data, underlyingToken, fee, relayFee, amount, params
        );
    }

    function crossChainTransferAssetRelay(
        uint256 dstChainId,
        address recipient,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable
        onlyGelatoRelayERC2771
    {
        address sender = _getMsgSender();
        _crossChainTransferAsset(_getMsgSender(), dstChainId, recipient, fee, amount, params);

        _transferRelayFee();

        uint256 relayFee = _getFee();
        _afterBridge(sender, relayFee);
        bytes32 id = _extractId(sender, dstChainId, recipient, bytes(""));

        emit CrossChainTransferAssetRelay(
            id, sender, dstChainId, recipient, underlyingToken, fee, relayFee, amount, params
        );
    }
}
