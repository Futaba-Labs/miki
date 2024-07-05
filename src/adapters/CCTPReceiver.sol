// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICCTPReceiver } from "../interfaces/ICCTPReceiver.sol";
import { IMessageTransmitter } from "../interfaces/IMessageTransmitter.sol";
import { IMikiReceiver } from "../interfaces/IMikiReceiver.sol";

/**
 * @title CCTPReceiver
 * @notice CCTPReceiver is a contract that receives the messages from the CCTP
 */
contract CCTPReceiver is ICCTPReceiver, Ownable {
    /* ----------------------------- Storage -------------------------------- */
    IMessageTransmitter public immutable messageTransmitter;

    IERC20 public immutable token;

    IMikiReceiver public immutable mikiReceiver;

    /* ----------------------------- Events -------------------------------- */

    event MessageReceived(
        bytes message, bytes attestation, address appReceiver, uint256 srcChainId, address srcAddress, bytes mikiMessage
    );

    event FailedMessageReceived(
        address appReceiver, uint256 srcChainId, address srcAddress, bytes mikiMessage, string reason
    );

    /* ----------------------------- Errors -------------------------------- */

    /* ----------------------------- Constructor -------------------------------- */
    /**
     * @notice Constructor
     * @param _initialOwner The initial owner of the contract
     */
    /**
     * @notice Constructor
     * @param _initialOwner The address of the initial owner of the contract
     * @param _messageTransmitter The address of the message transmitter
     * @param _mikiReceiver The address of the miki receiver
     * @param _token The address of the token
     */
    constructor(
        address _initialOwner,
        address _messageTransmitter,
        address _token,
        address _mikiReceiver
    )
        Ownable(_initialOwner)
    {
        messageTransmitter = IMessageTransmitter(_messageTransmitter);
        mikiReceiver = IMikiReceiver(_mikiReceiver);
        token = IERC20(_token);
    }

    /* ----------------------------- Functions -------------------------------- */

    function cctpReceive(
        bytes calldata _message,
        bytes calldata _attestation,
        address _appReceiver,
        uint256 _srcChainId,
        address _srcAddress,
        bytes calldata _mikiMessage
    )
        external
    {
        messageTransmitter.receiveMessage(_message, _attestation);
        uint256 amount = token.balanceOf(address(this)); // TODO: check if this is the correct way to get the amount
        bytes32 _id = bytes32(0);

        try mikiReceiver.mikiReceive(_srcChainId, _srcAddress, _appReceiver, address(token), amount, _mikiMessage, _id)
        {
            emit MessageReceived(_message, _attestation, _appReceiver, _srcChainId, _srcAddress, _mikiMessage);
        } catch Error(string memory reason) {
            emit FailedMessageReceived(_appReceiver, _srcChainId, _srcAddress, _mikiMessage, reason);
        } catch {
            emit FailedMessageReceived(_appReceiver, _srcChainId, _srcAddress, _mikiMessage, "Unknown error");
        }
    }

    /* ----------------------------- Internal functions -------------------------------- */
}
