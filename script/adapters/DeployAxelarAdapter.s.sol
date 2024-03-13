// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";

import { ETHTokenPool } from "../../src/pools/ETHTokenPool.sol";
import { AxelarAdapter } from "../../src/adapters/AxelarAdapter.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployAxelarAdapter is BaseScript {
    uint256[] chainIds = [11_155_420];
    string[] chainNames = ["optimism-sepolia"];
    address public gateway = 0xe1cE95479C84e9809269227C7F8524aE051Ae77a;
    address public gasService = 0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6;
    address[] public receivers = [0xAfFFd931b4A0738648591370c1C2c1C127098345]; // Optimism Sepolia Receiver
    address public owner;
    ETHTokenPool public ethTokenPool = ETHTokenPool(payable(0x1628FA7740c89308a8D9f543A8bb066AF48b0f65));
    AxelarAdapter public axelarAdapter;

    function run() public broadcast {
        owner = broadcaster;

        // Instantiate the BridgeAdapterMock.
        axelarAdapter = new AxelarAdapter(owner, gateway, gasService);

        // Set the bridge adapter.
        for (uint256 i; i < chainIds.length; i++) {
            ethTokenPool.setBridgeAdapter(chainIds[i], address(axelarAdapter));
        }

        // Set chain names.
        axelarAdapter.setChainIdToDomains(chainIds, chainNames);

        // Set the receiver.
        axelarAdapter.setChainIdToReceivers(chainIds, receivers);
    }
}
