// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IMikiAppReceiver } from "../interfaces/IMikiAppReceiver.sol";
import { IMikiReceiver } from "../interfaces/IMikiReceiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MikiReceiver
 * @notice This contract is used to receive messages from Adapters
 */
contract MikiReceiver is Ownable, IMikiReceiver {
    /* ----------------------------- Storage -------------------------------- */
    /// @notice Mapping: bridge receiver -> whether the adapter is registered or not
    mapping(address adapter => bool isAdapter) public adapters;

    /* ----------------------------- Events -------------------------------- */

    /**
     * @notice This event is emitted when a message is sent and a token is transferred
     * @param id The id of the message
     * @param srcChainId The source chain id
     * @param srcAddress The source address
     * @param token The token address
     * @param receiver The receiver address
     * @param amountLD The amount of the token
     * @param message The message
     */
    event SentMsgAndToken(
        bytes32 id,
        uint256 srcChainId,
        address srcAddress,
        address token,
        address receiver,
        uint256 amountLD,
        bytes message
    );

    /**
     * @notice This event is emitted when a message is sent and no token is transferred
     * @param id The id of the message
     * @param srcChainId The source chain id
     * @param srcAddress The source address
     * @param receiver The receiver address
     * @param message The message
     */
    event SentMsg(bytes32 id, uint256 srcChainId, address srcAddress, address receiver, bytes message);

    /**
     * @notice This event is emitted when a message is sent and a token is transferred
     * @param id The id of the message
     * @param srcChainId The source chain id
     * @param srcAddress The source address
     * @param token The token address
     * @param receiver The receiver address
     * @param amountLD The amount of the token
     * @param message The message
     * @param reason The reason of the failure
     */
    event FailedMsgAndToken(
        bytes32 id,
        uint256 srcChainId,
        address srcAddress,
        address token,
        address receiver,
        uint256 amountLD,
        bytes message,
        string reason
    );

    /**
     * @notice This event is emitted when a message is sent and no token is transferred
     * @param id The id of the message
     * @param srcChainId The source chain id
     * @param srcAddress The source address
     * @param receiver The receiver address
     * @param message The message
     * @param reason The reason of the failure
     */
    event FailedMsg(bytes32 id, uint256 srcChainId, address srcAddress, address receiver, bytes message, string reason);

    /**
     * @notice This event is emitted when an adapter is set
     * @param adapter The adapter address
     */
    event SetAdapter(address adapter);

    /**
     * @notice This event is emitted when an adapter is removed
     * @param adapter The adapter address
     */
    event RemoveAdapter(address adapter);

    /* ----------------------------- Erorrs -------------------------------- */

    /// @notice This error is emitted when the transfer of the token fails
    error TransferFailed();
    /// @notice This error is emitted when the adapter is invalid
    error InvalidAdapter();

    /* ----------------------------- Constructor -------------------------------- */
    constructor(address _initialOwner) Ownable(_initialOwner) { }

    /* ----------------------------- External Functions ----------------------------- */

    /**
     * @notice This function is used to receive a message from Adapters
     * @dev Revert if the adapter is not registered
     * @param srcChainId The source chain id
     * @param srcAddress The source address
     * @param receiver The receiver address
     * @param token The token address
     * @param amount The amount of the token
     * @param message The message
     * @param id The id of the message
     */
    function mikiReceive(
        uint256 srcChainId,
        address srcAddress,
        address receiver,
        address token,
        uint256 amount,
        bytes calldata message,
        bytes32 id
    )
        external
        payable
    {
        if (adapters[receiver]) {
            revert InvalidAdapter();
        }

        /// @dev If the amount is 0, only the message is sent.
        /// @dev If the amount is greater than 0, the condition is divided again when handling ERC20 or Native tokens.
        if (amount > 0) {
            if (token != address(0)) {
                bool success = IERC20(token).transfer(receiver, amount);
                if (!success) {
                    revert TransferFailed();
                }

                try IMikiAppReceiver(receiver).mikiReceive(srcChainId, srcAddress, token, amount, message) {
                    emit SentMsgAndToken(id, srcChainId, srcAddress, token, receiver, amount, message);
                } catch Error(string memory reason) {
                    emit FailedMsgAndToken(id, srcChainId, srcAddress, token, receiver, amount, message, reason);
                } catch {
                    emit FailedMsgAndToken(
                        id, srcChainId, srcAddress, token, receiver, amount, message, "Unknown error"
                    );
                }
            } else {
                try IMikiAppReceiver(receiver).mikiReceive{ value: amount }(
                    srcChainId, srcAddress, token, amount, message
                ) {
                    emit SentMsgAndToken(id, srcChainId, srcAddress, address(0), receiver, amount, message);
                } catch Error(string memory reason) {
                    emit FailedMsgAndToken(id, srcChainId, srcAddress, address(0), receiver, amount, message, reason);
                } catch {
                    emit FailedMsgAndToken(
                        id, srcChainId, srcAddress, address(0), receiver, amount, message, "Unknown error"
                    );
                }
            }
        } else {
            try IMikiAppReceiver(receiver).mikiReceiveMsg(srcChainId, srcAddress, message) {
                emit SentMsg(id, srcChainId, srcAddress, receiver, message);
            } catch Error(string memory reason) {
                emit FailedMsg(id, srcChainId, srcAddress, receiver, message, reason);
            } catch {
                emit FailedMsg(id, srcChainId, srcAddress, receiver, message, "Unknown error");
            }
        }
    }

    /**
     * @notice This function is used to set adapters
     * @param _adapters The adapters to set
     */
    function setAdapters(address[] memory _adapters) public onlyOwner {
        for (uint256 i = 0; i < _adapters.length; i++) {
            adapters[_adapters[i]] = true;
            emit SetAdapter(_adapters[i]);
        }
    }

    /**
     * @notice This function is used to remove adapters
     * @param _adapters The adapters to remove
     */
    function removeAdapters(address[] calldata _adapters) external onlyOwner {
        for (uint256 i = 0; i < _adapters.length; i++) {
            adapters[_adapters[i]] = false;
            emit RemoveAdapter(_adapters[i]);
        }
    }

    fallback() external payable { }

    receive() external payable { }
}
