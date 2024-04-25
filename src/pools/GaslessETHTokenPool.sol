// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { ETHTokenPool } from "./ETHTokenPool.sol";
import { GelatoRelayContextERC2771 } from "@gelatonetwork/relay-context/contracts/GelatoRelayContextERC2771.sol";

contract GaslessETHTokenPool is ETHTokenPool, GelatoRelayContextERC2771 {
    /* ----------------------------- Events -------------------------------- */
    event CrossChainContractCallRelay(
        address sender, uint256 dstChainId, address recipient, bytes data, uint256 fee, uint256 relayFee, bytes params
    );

    event CrossChainContractCallWithAssetRelay(
        address sender,
        uint256 dstChainId,
        address recipient,
        bytes data,
        uint256 fee,
        uint256 relayFee,
        uint256 amount,
        bytes params
    );

    event CrossChainTransferAssetRelay(
        address sender,
        uint256 dstChainId,
        address recipient,
        uint256 fee,
        uint256 relayFee,
        uint256 amount,
        bytes params
    );
    /* ----------------------------- Constructor -------------------------------- */

    constructor(
        address _l2AssetManager,
        address _underlyingToken,
        address _operator
    )
        ETHTokenPool(_l2AssetManager, _underlyingToken, _operator)
    { }

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

        emit CrossChainContractCallRelay(sender, dstChainId, recipient, data, fee, relayFee, params);
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

        emit CrossChainContractCallWithAssetRelay(sender, dstChainId, recipient, data, fee, relayFee, amount, params);
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

        emit CrossChainTransferAssetRelay(sender, dstChainId, recipient, fee, relayFee, amount, params);
    }
}
