// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { CCTPReceiver } from "../../src/adapters/CCTPReceiver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CCTPAdapterScript is BaseScript {
    CCTPReceiver cctpReceiver;
    address usdc = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;
    address messageTransmitter = 0x7865fAfC2db2093669d92c0F33AeEF291086BEFD;
    address mikiReceiver = 0x995B7Ca5b97A58DF26A431b6124618B8b9509534;

    address appReceiver = 0x5d3144125BE4b16e9e79c77E8F32b7D564dfa85a; // NFT Receiver
    uint256 srcChainId = 421614; // Base Sepolia
    address srcAddress = 0x39338FD37f41BabC04e119332198346C0EB31022;
    bytes mikiMessage = "0x39338FD37f41BabC04e119332198346C0EB31022"; // mint to address

    function run(bytes memory _message, bytes memory _attestation) public broadcast {
        cctpReceiver = new CCTPReceiver(broadcaster, messageTransmitter, usdc, mikiReceiver);
        cctpReceiver.cctpReceive(_message, _attestation, appReceiver, srcChainId, srcAddress, mikiMessage);
    }
}
