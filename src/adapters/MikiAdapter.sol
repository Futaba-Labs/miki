// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import {
    SendParam,
    MessagingReceipt,
    OFTReceipt,
    IOFT
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import { IOAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol";
import { MessagingFee } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MikiAdapter is IL2BridgeAdapter, Ownable {
    using SafeERC20 for IERC20;
    /* ----------------------------- Storage -------------------------------- */

    address public mikiToken;
    mapping(uint256 => uint32) public eidOf;
    mapping(uint256 => address) public receivers;

    /* ----------------------------- Erorrs -------------------------------- */

    error MismatchLength();
    error InvalidLength();

    /* ----------------------------- Constructor -------------------------------- */
    constructor(address _mikiToken, address _initialOwner) Ownable(_initialOwner) {
        mikiToken = _mikiToken;
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
        bytes memory payload = abi.encode(sender, recipient, message);
        address receiver = receivers[dstChainId];

        (uint256 minAmount, bytes memory option) = abi.decode(params, (uint256, bytes));
        uint32 eid = eidOf[dstChainId];
        SendParam memory sendParam = SendParam(eid, _addressToBytes32(receiver), amount, minAmount, option, payload, "");
        MessagingFee memory msgFee = MessagingFee(fee, 0);

        IERC20(mikiToken).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(mikiToken).approve(address(this), amount);

        IOFT(mikiToken).send{ value: msgFee.nativeFee }(sendParam, msgFee, msg.sender);
    }

    function execCrossChainTransferAsset(
        address sender,
        uint256 dstChainId,
        address recipient,
        address asset,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    )
        external
        payable
    {
        (uint256 minAmount, bytes memory option) = abi.decode(params, (uint256, bytes));
        uint32 eid = eidOf[dstChainId];

        SendParam memory sendParam = SendParam(eid, _addressToBytes32(recipient), amount, minAmount, option, "", "");
        MessagingFee memory msgFee = MessagingFee(fee, 0);

        IERC20(mikiToken).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(mikiToken).approve(address(this), amount);

        IOFT(mikiToken).send{ value: msgFee.nativeFee }(sendParam, msgFee, msg.sender);
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
        (uint256 minAmount, bytes memory option) = abi.decode(params, (uint256, bytes));

        bytes memory payload;
        if (message.length != 0) {
            payload = abi.encode(sender, recipient, message);
        }

        address receiver = receivers[dstChainId];
        uint32 eid = eidOf[dstChainId];
        SendParam memory sendParam = SendParam(eid, _addressToBytes32(receiver), amount, minAmount, option, message, "");
        MessagingFee memory msgFee = IOFT(mikiToken).quoteSend(sendParam, false);
        return msgFee.nativeFee;
    }

    function setEids(uint256[] calldata _dstChainIds, uint32[] calldata _eids) external onlyOwner {
        uint256 dstChainsLen = _dstChainIds.length;
        uint256 eidsLen = _eids.length;

        if (dstChainsLen == 0 || eidsLen == 0) revert InvalidLength();

        if (dstChainsLen != eidsLen) revert MismatchLength();

        for (uint256 i; i < dstChainsLen; i++) {
            eidOf[_dstChainIds[i]] = _eids[i];
        }
    }

    function setPeers(uint256[] calldata _dstChainIds, address[] calldata _peers) external onlyOwner {
        uint256 dstChainsLen = _dstChainIds.length;
        uint256 peersLen = _peers.length;

        if (dstChainsLen == 0 || peersLen == 0) revert InvalidLength();

        if (dstChainsLen != peersLen) revert MismatchLength();

        for (uint256 i; i < dstChainsLen; i++) {
            uint32 eid = eidOf[_dstChainIds[i]];
            bytes32 peer = _addressToBytes32(_peers[i]);
            IOAppCore(mikiToken).setPeer(eid, peer);
        }
    }

    function setReceivers(uint256[] calldata _dstChainIds, address[] calldata _receivers) external onlyOwner {
        uint256 dstChainsLen = _dstChainIds.length;
        uint256 receiversLen = _receivers.length;

        if (dstChainsLen == 0 || receiversLen == 0) revert InvalidLength();

        if (dstChainsLen != receiversLen) revert MismatchLength();

        for (uint256 i; i < dstChainsLen; i++) {
            receivers[_dstChainIds[i]] = _receivers[i];
        }
    }

    function _addressToBytes32(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }
}
