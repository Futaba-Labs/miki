// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import { IStargateRouter } from "../interfaces/IStargateRouter.sol";
import { ILayerZeroEndpoint } from "../interfaces/ILayerZeroEndpoint.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract LayerZeroAdapter is IL2BridgeAdapter, Ownable {
    /* ----------------------------- Storage -------------------------------- */
    address public immutable stargateRouter;
    address public immutable gateaway;
    mapping(uint256 => address) public chainIdToReceiver;
    mapping(uint256 => uint16) public chainIds;

    /* ----------------------------- Events -------------------------------- */
    event SetChainId(uint256 chainId, uint16 chainIdUint16);

    /* ----------------------------- Constructor -------------------------------- */
    constructor(
        address _initialOwner,
        address _stargateRouter,
        address _gateway,
        uint256[] memory _chainIds,
        uint16[] memory _chainIdUint16
    )
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
        address receiver = chainIdToReceiver[dstChainId];
        uint16 chainIdUint16 = chainIds[dstChainId];
        bytes memory trustedRemote = abi.encodePacked(receiver, address(this));

        bytes memory payload = abi.encode(sender, recipient, message);

        ILayerZeroEndpoint(gateaway).send{ value: fee }(
            chainIdUint16, // destination LayerZero chainId
            trustedRemote, // send to this address on the destination
            payload, // bytes payload
            payable(msg.sender), // refund address
            address(0x0), // future parameter
            bytes("") // adapterParams (see "Advanced Features")
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
        (address to, bool isNative, bool useStargate) = abi.decode(params, (address, bool, bool));
        bytes memory toAddress = abi.encodePacked(to);
        uint16 chainIdUint16 = chainIds[dstChainId];

        bytes memory payload = abi.encode(to, isNative, message);

        if (useStargate) {
            return _estimateSGFee(chainIdUint16, toAddress, payload);
        } else {
            return _estimateLZFee(chainIdUint16, payload);
        }
    }

    function setChainId(uint256 _chainId, uint16 _chainIdUint16) public onlyOwner {
        chainIds[_chainId] = _chainIdUint16;
        emit SetChainId(_chainId, _chainIdUint16);
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

    function _estimateLZFee(uint16 chainIdUint16, bytes memory payload) internal view returns (uint256) {
        (uint256 nativeFee, uint256 zroFee) =
            ILayerZeroEndpoint(gateaway).estimateFees(chainIdUint16, address(this), payload, false, bytes(""));

        return nativeFee;
    }
}
