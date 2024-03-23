// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";

import { ETHTokenPool } from "../../src/pools/ETHTokenPool.sol";
import { LayerZeroReceiver } from "../../src/adapters/LayerZeroReceiver.sol";
import { SampleMikiReceiver } from "../../src/examples/SampleMikiReceiver.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployLZReceiver is BaseScript {
    address public stargateRouter = 0xa2dfFdDc372C6aeC3a8e79aAfa3953e8Bc956D63;
    address public gateway = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address public owner;
    LayerZeroReceiver public lzReceiver;
    SampleMikiReceiver public mikiReceiver;
    uint256[] public chainIds = [11_155_420, 421_614];
    uint32[] public eids = [40_232, 40_231];

    function run() public broadcast {
        owner = broadcaster;

        // Instantiate the BridgeAdapterMock.
        lzReceiver = new LayerZeroReceiver(stargateRouter, gateway, owner);

        // set chainIds and eids
        lzReceiver.setChainIds(eids, chainIds);

        // Instantiate the SampleMikiReceiver.
        mikiReceiver = new SampleMikiReceiver();
    }
}
