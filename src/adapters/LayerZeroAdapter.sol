// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import { IStargateRouter } from "../interfaces/IStargateRouter.sol";
import { ILayerZeroEndpoint } from "../interfaces/ILayerZeroEndpoint.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OAppSender } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { OAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppCore.sol";
import { MessagingFee } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

contract LayerZeroAdapter is IL2BridgeAdapter, OAppSender {
    /* ----------------------------- Storage -------------------------------- */
    address public immutable stargateRouter;
    address public immutable gateaway;
    mapping(uint256 => address) public chainIdToReceiver;
    mapping(uint256 => uint16) public chainIds;
    mapping(uint256 => uint32) public eidOf;

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
        address _stargateRouter,
        address _gateway,
        uint256[] memory _chainIds,
        uint16[] memory _chainIdUint16
    )
        OAppCore(_gateway, _initialOwner)
        Ownable(_initialOwner)
    {
        stargateRouter = _stargateRouter;
        gateaway = _gateway;
        for (uint256 i; i < _chainIds.length;) {
            chainIds[_chainIds[i]] = _chainIdUint16[i];

            unchecked {
                ++i;
            }
        }
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
        (address to, bool isNative) = abi.decode(params, (address, bool));

        bytes memory payload = abi.encode(recipient, isNative, message);

        uint16 chainIdUint16 = chainIds[dstChainId];
        address receiver = chainIdToReceiver[dstChainId];
        bytes memory encodedReceiver = abi.encodePacked(receiver);

        if (isNative) {
            IStargateRouter(stargateRouter).swapETHAndCall{ value: amount + fee }(
                chainIdUint16,
                payable(address(this)),
                encodedReceiver,
                IStargateRouter.SwapAmount(amount, 0),
                IStargateRouter.lzTxObj(0, 0, "0x"),
                payload
            );
        } else {
            // TODO Implement the cross chain transfer asset (ERC20)
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
        (address to, bool isNative) = abi.decode(params, (address, bool));
        uint16 chainIdUint16 = chainIds[dstChainId];
        bytes memory encodedRecipient = abi.encodePacked(recipient);

        if (isNative) {
            IStargateRouter(stargateRouter).swapETHAndCall{ value: amount + fee }(
                chainIdUint16,
                payable(address(this)),
                encodedRecipient,
                IStargateRouter.SwapAmount(amount, 0),
                IStargateRouter.lzTxObj(0, 0, "0x"),
                bytes("")
            );
        } else {
            // TODO Implement the cross chain transfer asset (ERC20)
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
        (bytes memory options, bytes memory sgParams) = abi.decode(params, (bytes, bytes));

        if (sgParams.length > 0) {
            uint16 chainIdUint16 = chainIds[dstChainId];
            (address to, bool isNative) = abi.decode(sgParams, (address, bool));
            bytes memory toAddress = abi.encodePacked(to);
            bytes memory payload = abi.encode(to, isNative, message);

            return _estimateSGFee(chainIdUint16, toAddress, payload);
        } else {
            uint32 eid = eidOf[dstChainId];
            return _estimateLZFee(eid, sender, recipient, message, options);
        }
    }

    function setChainId(uint256 _chainId, uint16 _chainIdUint16) public onlyOwner {
        chainIds[_chainId] = _chainIdUint16;
        emit SetChainId(_chainId, _chainIdUint16);
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

    function setChainIdToReceivers(uint256[] memory _chainIds, address[] memory _receivers) public onlyOwner {
        for (uint256 i; i < _chainIds.length;) {
            chainIdToReceiver[_chainIds[i]] = _receivers[i];

            unchecked {
                ++i;
            }
        }
    }

    /* ----------------------------- Internal functions -------------------------------- */

    function _estimateSGFee(
        uint16 chainIdUint16,
        bytes memory to,
        bytes memory payload
    )
        internal
        view
        returns (uint256)
    {
        (uint256 fee, uint256 poolId) = IStargateRouter(stargateRouter).quoteLayerZeroFee(
            chainIdUint16, 1, to, payload, IStargateRouter.lzTxObj(0, 0, "0x")
        );
        return fee;
    }

    function _estimateLZFee(
        uint32 eid,
        address sender,
        address recipient,
        bytes memory message,
        bytes memory options
    )
        internal
        view
        returns (uint256)
    {
        bytes memory _payload = abi.encode(sender, recipient, message);
        MessagingFee memory fee = _quote(eid, _payload, options, false);

        return fee.nativeFee;
    }
}
