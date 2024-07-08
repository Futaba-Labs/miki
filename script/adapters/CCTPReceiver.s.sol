// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { CCTPReceiver } from "../../src/adapters/CCTPReceiver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CCTPAdapterScript is BaseScript {
    /* constants */
    address constant usdc = 0x036CbD53842c5426634e7929541eC2318f3dCF7e; // Base Sepolia
    address constant messageTransmitter = 0x7865fAfC2db2093669d92c0F33AeEF291086BEFD; // Base Sepolia
    address constant mikiReceiver = 0x3063E6ed87eE62337ca7c976EF4B6c4d941D013C; // Base Sepolia

    address constant deployedCCTPReceiver = 0x1d3E172C336D782B7d3869A9541b039DA376AA5C;
    address constant appReceiver = 0x5d3144125BE4b16e9e79c77E8F32b7D564dfa85a; // NFT Receiver
    // address constant appReceiver = 0x928842BB2aD5A2161277e62260e6AC5c5C16d6c1; // EmptyAppReceiver
    uint256 constant srcChainId = 421_614; // Arbitrum Sepolia
    address constant srcAddress = 0x39338FD37f41BabC04e119332198346C0EB31022;
    bytes constant mikiMessage = "0x39338FD37f41BabC04e119332198346C0EB31022"; // mint to address

    /* functions */
    function deploy() public broadcast {
        new CCTPReceiver(broadcaster, messageTransmitter, usdc, mikiReceiver);
    }

    function cctpReceive(bytes memory _message, bytes memory _attestation) public broadcast {
        CCTPReceiver cctpReceiver = CCTPReceiver(deployedCCTPReceiver);
        cctpReceiver.cctpReceive(_message, _attestation, appReceiver, srcChainId, srcAddress, mikiMessage);
    }
}
