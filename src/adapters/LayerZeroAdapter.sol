// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import { IStargateRouter } from "../interfaces/IStargateRouter.sol";
import { ILayerZeroEndpoint } from "../interfaces/ILayerZeroEndpoint.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OAppSender } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { OAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppCore.sol";
import { MessagingFee } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { ILayerZeroAdapter } from "../interfaces/ILayerZeroAdapter.sol";

contract LayerZeroAdapter is OAppSender, ILayerZeroAdapter {
    /* ----------------------------- Storage -------------------------------- */
    mapping(uint256 chainId => uint32 eid) public eidOf;

    /* ----------------------------- Events -------------------------------- */
    event SetChainId(uint256 chainId, uint16 chainIdUint16);
    event SetEid(uint256 chainId, uint32 eid);

    /* ----------------------------- Errors -------------------------------- */
    error MismatchLength();
    error InvalidLength();
    error NotSupportedNetwork();

    /* ----------------------------- Constructor -------------------------------- */
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

    function lzSend(
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
        uint32 eid = eidOf[dstChainId];
        if (eid == 0) {
            revert NotSupportedNetwork();
        }

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
        (bytes memory options, bytes memory sgParams) = abi.decode(params, (bytes, bytes));

        return _estimateLZFee(dstChainId, sender, recipient, message, options);
    }

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
