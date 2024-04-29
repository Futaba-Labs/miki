// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IOAppComposer } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppComposer.sol";
import { OAppReceiver } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppReceiver.sol";
import { Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppReceiver.sol";
import { OAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppCore.sol";
import { OFTComposeMsgCodec } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMikiReceiver } from "../interfaces/IMikiReceiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LayerZeroReceiver
 * @notice This contract is the receiver of the messages from the LayerZero network
 */
contract LayerZeroReceiver is IOAppComposer, OAppReceiver {
    using Address for address;
    using OFTComposeMsgCodec for bytes;
    /* ----------------------------- Storage -------------------------------- */
    /// @notice The stargate router address
    /// @dev Not currently in use

    address public immutable STARGATE_ROUTER;

    /// @notice The miki receiver address
    address public immutable MIKI_RECEIVER;

    /// @notice Mapping: Endpoint ID to Chain ID
    mapping(uint32 => uint256) public chainIdOf;

    /* ----------------------------- Erorrs -------------------------------- */

    /// @notice Error emitted when the router is invalid
    error InvalidRouter();

    /// @notice Error emitted when the call data is invalid
    error InvalidCall(bytes data);

    /// @notice Error emitted when the length of the arrays is mismatching
    error MismatchLength();

    /// @notice Error emitted when the length of the arrays is invalid
    error InvalidLength();

    /// @notice Error emitted when the transfer failed
    error TransferFailed();

    /* ----------------------------- Constructor -------------------------------- */
    /**
     * @notice Constructor
     * @param _stargateRouter The stargate router address
     * @param _mikiReceiver The miki receiver address
     * @param _gateway The gateway address
     * @param _initialOwner The initial owner address
     */
    constructor(
        address _stargateRouter,
        address _mikiReceiver,
        address _gateway,
        address _initialOwner
    )
        OAppCore(_gateway, _initialOwner)
        Ownable(_initialOwner)
    {
        STARGATE_ROUTER = _stargateRouter;
        MIKI_RECEIVER = _mikiReceiver;
    }

    /**
     * @notice This function is the receiver of the messages from the LayerZero network
     * @param _origin The origin of the message
     * @param payload The payload of the message
     */
    function _lzReceive(
        Origin calldata _origin, // struct containing info about the message sender
        bytes32, // global packet identifier
        bytes calldata payload, // encoded message payload being received
        address, // the Executor address.
        bytes calldata // arbitrary data appended by the Executor
    )
        internal
        override
    {
        uint256 chainId = chainIdOf[_origin.srcEid];
        (address sender, address receiver, bytes memory messageWithId) = abi.decode(payload, (address, address, bytes));
        (bytes32 id, bytes memory message) = abi.decode(messageWithId, (bytes32, bytes));
        IMikiReceiver(MIKI_RECEIVER).mikiReceive(chainId, sender, receiver, address(0), 0, message, id);
    }

    /**
     * @notice This function is the receiver of the messages and OFT from the LayerZero network
     * @dev Not currently in use
     * @param _from The sender address
     * @param _message The message
     */
    function lzCompose(
        address _from,
        bytes32,
        bytes calldata _message,
        address,
        bytes calldata /*_extraData*/
    )
        external
        payable
    {
        uint32 srcEid = _message.srcEid();
        uint256 amountLD = _message.amountLD();
        bytes memory composeMsg = _message.composeMsg();
        (address sender, address receiver, bytes memory messageWithId) =
            abi.decode(composeMsg, (address, address, bytes));
        (bytes32 id, bytes memory message) = abi.decode(messageWithId, (bytes32, bytes));

        bool success = IERC20(_from).transfer(MIKI_RECEIVER, amountLD);
        if (!success) {
            revert TransferFailed();
        }

        uint256 chainId = chainIdOf[srcEid];

        IMikiReceiver(MIKI_RECEIVER).mikiReceive(chainId, sender, receiver, _from, amountLD, message, id);
    }

    /**
     * @notice This function is the receiver of the messages from the Stargate network
     * @param _eids The endpoint ids
     * @param _chainIds The chain ids
     */
    function setChainIds(uint32[] calldata _eids, uint256[] calldata _chainIds) external {
        uint256 eidsLen = _eids.length;
        uint256 chainIdsLen = _chainIds.length;

        if (eidsLen == 0 || chainIdsLen == 0) revert InvalidLength();

        if (eidsLen != chainIdsLen) revert MismatchLength();

        for (uint256 i; i < eidsLen; i++) {
            chainIdOf[_eids[i]] = _chainIds[i];
        }
    }

    fallback() external payable { }

    receive() external payable { }
}
