// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OAppSender } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { OAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppCore.sol";
import { MessagingFee } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { ILayerZeroAdapter } from "../interfaces/ILayerZeroAdapter.sol";

/**
 * @title LayerZeroAdapter
 * @notice LayerZeroAdapter is an adapter contract for using LayerZero with Messaging
 */
contract LayerZeroAdapter is OAppSender, ILayerZeroAdapter {
    /* ----------------------------- Storage -------------------------------- */
    /// @notice Mapping: ChainId => EndpointId
    mapping(uint256 chainId => uint32 eid) public eidOf;

    /* ----------------------------- Events -------------------------------- */
    /// @notice Emitted when the chain id is set
    event SetChainId(uint256 chainId, uint16 chainIdUint16);

    /// @notice Emitted when the endpoint id is set
    event SetEid(uint256 chainId, uint32 eid);

    /* ----------------------------- Errors -------------------------------- */
    /// @notice Emitted when the length of the chain ids and endpoint ids does not match
    error MismatchLength();

    /// @notice Emitted when the length of the chain ids and endpoint ids does not match
    error InvalidLength();

    /// @notice Emitted when the network is not supported
    error NotSupportedNetwork();

    /* ----------------------------- Constructor -------------------------------- */
    /**
     * @notice Constructor
     * @param _initialOwner The initial owner of the contract
     * @param _gateway The gateway address
     * @param _chainIds The chain ids
     * @param _eids The endpoint ids
     */
    constructor(
        address _initialOwner,
        address _gateway,
        uint256[] memory _chainIds,
        uint32[] memory _eids
    )
        OAppCore(_gateway, _initialOwner)
        Ownable(_initialOwner)
    {
        setEids(_chainIds, _eids);
    }

    /**
     * @notice Send message via LayerZero
     * @dev Revert if the network is not supported
     * @param sender The sender address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param message The message
     * @param params The parameters (options, sgParams)
     */
    function lzSend(
        address sender,
        uint256 dstChainId,
        address recipient,
        bytes calldata message,
        uint256,
        bytes calldata params
    )
        external
        payable
    {
        uint32 eid = eidOf[dstChainId];
        if (eid == 0) {
            revert NotSupportedNetwork();
        }

        /// @dev Now we do not use `sgParams` (parameter used for stargate)
        (bytes memory options, bytes memory sgParams) = abi.decode(params, (bytes, bytes));
        bytes memory _payload = abi.encode(sender, recipient, message);

        _lzSend(
            eid, // Destination chain's endpoint ID.
            _payload, // Encoded message payload being sent.
            options, // Message execution options (e.g., gas to use on destination).
            MessagingFee(msg.value, 0), // Fee struct containing native gas and ZRO token.
            payable(msg.sender) // The refund address in case the send call reverts.
        );
    }

    /**
     * @notice Estimate the fee for sending a message via LayerZero
     * @param sender The sender address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param message The message
     * @param params The parameters (options, sgParams)
     * @return The messaging fee (native token)
     */
    function estimateFee(
        address sender,
        uint256 dstChainId,
        address recipient,
        address,
        bytes calldata message,
        uint256,
        bytes calldata params
    )
        external
        view
        returns (uint256)
    {
        /// @dev Now we do not use `sgParams` (parameter used for stargate)
        (bytes memory options, bytes memory sgParams) = abi.decode(params, (bytes, bytes));

        return _estimateLZFee(dstChainId, sender, recipient, message, options);
    }

    /**
     * @notice Set the endpoint ids
     * @dev Revert if the length of the chain ids and endpoint ids does not match
     * @param _chainIds The chain ids
     * @param _eids The endpoint ids
     */
    function setEids(uint256[] memory _chainIds, uint32[] memory _eids) public onlyOwner {
        uint256 chainIdsLength = _chainIds.length;
        uint256 eidsLength = _eids.length;

        if (chainIdsLength == 0 || eidsLength == 0) {
            revert InvalidLength();
        }

        if (chainIdsLength != eidsLength) {
            revert MismatchLength();
        }
        for (uint256 i; i < chainIdsLength;) {
            eidOf[_chainIds[i]] = _eids[i];

            emit SetEid(_chainIds[i], _eids[i]);

            unchecked {
                ++i;
            }
        }
    }

    /* ----------------------------- Internal functions -------------------------------- */
    /**
     * @notice Estimate the fee for sending a message via LayerZero
     * @param dstChainId The destination chain id
     * @param sender The sender address
     * @param recipient The recipient address
     * @param message The message
     * @param options The options (Byte data with gas limit, etc. set when receiving messages)
     */
    function _estimateLZFee(
        uint256 dstChainId,
        address sender,
        address recipient,
        bytes memory message,
        bytes memory options
    )
        internal
        view
        returns (uint256)
    {
        bytes32 id = keccak256(abi.encodePacked(sender, dstChainId, recipient, message));
        bytes memory messageWithId = abi.encode(id, message);
        bytes memory _payload = abi.encode(sender, recipient, messageWithId);
        uint32 eid = eidOf[dstChainId];
        MessagingFee memory fee = _quote(eid, _payload, options, false);

        return fee.nativeFee;
    }
}
