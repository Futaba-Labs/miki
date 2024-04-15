// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { MikiReceiver } from "../../src/adapters/MikiReceiver.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract MikiReceiverScript is BaseScript {
    MikiReceiver public mikiReceiver;

    function run() public {
        Chains[] memory deployForks = new Chains[](2);
        deployForks[0] = Chains.OptimismSepolia;
        deployForks[1] = Chains.BaseSepolia;

        for (uint256 i; i < deployForks.length; i++) {
            string memory chainKey = _getChainKey(networks[deployForks[i]].chainId);

            _createSelectFork(deployForks[i]);

            _deployMikiReceiver();

            vm.writeJson(
                vm.toString(address(mikiReceiver)), deploymentPath, string.concat(chainKey, ".adapters.mikiReceiver")
            );
        }
    }

    function deployMikiReceiver() public {
        _deployMikiReceiver();
        string memory chainKey = _getChainKey(block.chainid);
        vm.writeJson(
            vm.toString(address(mikiReceiver)), deploymentPath, string.concat(chainKey, ".adapters.mikiReceiver")
        );
    }

    function setAdapters(address[] memory adapters) public broadcast {
        string memory chainKey = _getChainKey(block.chainid);
        address mikiReceiverAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.mikiReceiver"));
        mikiReceiver = MikiReceiver(payable(mikiReceiverAddr));
        mikiReceiver.setAdapters(adapters);
    }

    function _deployMikiReceiver() internal broadcast {
        mikiReceiver = new MikiReceiver(broadcaster);
    }
}
