// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";

import { ETHTokenPool } from "../../src/pools/ETHTokenPool.sol";
import { AxelarReceiver } from "../../src/adapters/AxelarReceiver.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployAxelarReceiver is BaseScript {
    address public gateway = 0xe432150cce91c13a887f7D836923d5597adD8E31; // Optimism Sepolia Gateway
    AxelarReceiver public axelarReceiver;

    function run() public broadcast {
        // Instantiate the BridgeAdapterMock.
        axelarReceiver = new AxelarReceiver(gateway);
    }
}
