// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "./Base.s.sol";

import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { LayerZeroReceiver } from "../src/adapters/LayerZeroReceiver.sol";
import { HelloWorld } from "../src/examples/HelloWorld.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployLZReceiver is BaseScript {
    address public stargateRouter = 0xa2dfFdDc372C6aeC3a8e79aAfa3953e8Bc956D63;
    address public owner;
    LayerZeroReceiver public lzReceiver;
    HelloWorld public helloWorld;

    function run() public broadcast {
        owner = broadcaster;

        // Instantiate the BridgeAdapterMock.
        lzReceiver = new LayerZeroReceiver(stargateRouter);

        // Instantiate the HelloWorld contract.
        helloWorld = new HelloWorld();
    }
}
