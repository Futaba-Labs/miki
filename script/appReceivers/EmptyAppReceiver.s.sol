// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { EmptyAppReceiver } from "../../src/examples/EmptyAppReceiver.sol";

address constant mikiReceiver = 0x995B7Ca5b97A58DF26A431b6124618B8b9509534; // Miki Receiver on Base Sepolia

contract EmptyAppReceiverScript is BaseScript {
    function deploy() public broadcast {
        new EmptyAppReceiver(mikiReceiver);
    }
}
