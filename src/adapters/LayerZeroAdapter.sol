// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import { IStargateRouter } from "../interfaces/IStargateRouter.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract LayerZeroAdapter is IL2BridgeAdapter, Ownable {
    /* ----------------------------- Storage -------------------------------- */
    address public immutable stargateRouter;
    address public receiver;
    mapping(uint256 => uint16) public chainIds;

    /* ----------------------------- Events -------------------------------- */
    event SetChainId(uint256 chainId, uint16 chainIdUint16);

    /* ----------------------------- Constructor -------------------------------- */
    constructor(
        address _initialOwner,
        address _stargateRouter,
        address _receiver,
        uint256[] memory _chainIds,
        uint16[] memory _chainIdUint16
    )
        Ownable(_initialOwner)
    {
        stargateRouter = _stargateRouter;
        receiver = _receiver;
        for (uint256 i; i < _chainIds.length;) {
            chainIds[_chainIds[i]] = _chainIdUint16[i];

            unchecked {
                ++i;
            }
        }
    }

    function execCrossChainContractCall(
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
        uint256 dstChainId,
        bytes calldata message,
        bytes calldata params
    )
        external
        view
        returns (uint256)
    {
        (address to, bool isNative) = abi.decode(params, (address, bool));
        bytes memory toAddress = abi.encodePacked(to);
        uint16 chainIdUint16 = chainIds[dstChainId];

        bytes memory payload = abi.encode(to, isNative, message);

        (uint256 fee, uint256 poolId) = IStargateRouter(stargateRouter).quoteLayerZeroFee(
            chainIdUint16, 1, toAddress, payload, IStargateRouter.lzTxObj(0, 0, "0x")
        );
        return fee;
    }

    function setChainId(uint256 _chainId, uint16 _chainIdUint16) public onlyOwner {
        chainIds[_chainId] = _chainIdUint16;
        emit SetChainId(_chainId, _chainIdUint16);
    }
}
