// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";

import { ETHTokenPool } from "../../src/pools/ETHTokenPool.sol";
import { LayerZeroReceiver } from "../../src/adapters/LayerZeroReceiver.sol";
import { SampleMikiReceiver } from "../../src/examples/SampleMikiReceiver.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract LZReceiverScript is BaseScript {
    LayerZeroReceiver public lzReceiver;
    SampleMikiReceiver public mikiReceiver;

    function run() public {
        Chains[] memory deployForks = new Chains[](2);
        deployForks[0] = Chains.ArbitrumSepolia;
        deployForks[1] = Chains.PolygonMumbai;

        for (uint256 i = 0; i < deployForks.length; i++) {
            string memory chainKey = _getChainKey(networks[deployForks[i]].chainId);
            address gateway =
                vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.layerZero.gateway"));
            address mikiReceiver =
                vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.mikiReceiver"));

            _createSelectFork(deployForks[i]);

            _deployLZReceiver(mikiReceiver, gateway);

            vm.writeJson(
                vm.toString(address(lzReceiver)),
                deploymentPath,
                string.concat(chainKey, ".adapters.layerZero.receiver")
            );

            vm.writeJson(
                vm.toString(address(lzReceiver)), deploymentPath, string.concat(chainKey, ".adapters.miki.receiver")
            );
        }
    }

    function setChainIds() public broadcast {
        string memory chainKey = _getChainKey(block.chainid);
        address lzReceiverAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.receiver"));

        Chains[] memory deployForks = new Chains[](2);
        deployForks[0] = Chains.ArbitrumSepolia;
        deployForks[1] = Chains.PolygonMumbai;

        uint256[] memory chainIds = new uint256[](deployForks.length - 1);
        uint32[] memory eids = new uint32[](deployForks.length - 1);

        for (uint256 i = 0; i < deployForks.length; i++) {
            if (networks[deployForks[i]].chainId == block.chainid) {
                continue;
            }

            chainIds[i] = networks[deployForks[i]].chainId;
            eids[i] = networks[deployForks[i]].eid;
        }

        LayerZeroReceiver(payable(lzReceiverAddr)).setChainIds(eids, chainIds);
    }

    function deployLZReceiver() public {
        string memory chainKey = _getChainKey(block.chainid);
        address gateway = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.layerZero.gateway"));
        address mikiReceiverAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.mikiReceiver"));
        _deployLZReceiver(mikiReceiverAddr, gateway);
        vm.writeJson(
            vm.toString(address(lzReceiver)), deploymentPath, string.concat(chainKey, ".adapters.layerZero.receiver")
        );
    }

    function _deployLZReceiver(address mikiReceiverAddr, address gateway) internal broadcast {
        lzReceiver = new LayerZeroReceiver(gateway, mikiReceiverAddr, gateway, broadcaster);
    }
}
