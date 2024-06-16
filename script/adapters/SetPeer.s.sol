// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";

import { ETHTokenPool } from "../../src/pools/ETHTokenPool.sol";
import { MikiTestToken } from "../../src/adapters/MikiTestToken.sol";
import { LayerZeroAdapter } from "../../src/adapters/LayerZeroAdapter.sol";
import { LayerZeroReceiver } from "../../src/adapters/LayerZeroReceiver.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract SetPeer is BaseScript {
    function setMikiPeer() public broadcast {
        for (uint256 i = 0; i < lzChains.length; i++) {
            Network memory lzChain = networks[lzChains[i]];
            if (lzChain.chainId == block.chainid) continue;
            string memory targetChainKey = _getChainKey(lzChain.chainId);
            address peerAddress =
                vm.parseJsonAddress(deploymentsJson, string.concat(targetChainKey, ".adapters.miki.token"));

            string memory srcChainKey = _getChainKey(block.chainid);
            address mikiAddress =
                vm.parseJsonAddress(deploymentsJson, string.concat(srcChainKey, ".adapters.miki.token"));

            MikiTestToken miki = MikiTestToken(mikiAddress);
            miki.setPeer(lzChain.eid, bytes32(uint256(uint160(peerAddress))));
        }
    }

    function setLzAdapterPeer() public broadcast {
        string memory srcChainKey = _getChainKey(block.chainid);
        Network memory hubNetwork = networks[Chains.ArbitrumSepolia];

        if (block.chainid == hubNetwork.chainId) {
            for (uint256 i = 0; i < lzChains.length; i++) {
                Network memory lzChain = networks[lzChains[i]];
                string memory targetChainKey = _getChainKey(lzChain.chainId);
                address peerAddress =
                    vm.parseJsonAddress(deploymentsJson, string.concat(targetChainKey, ".adapters.layerZero.receiver"));

                address lzAdapterAddress =
                    vm.parseJsonAddress(deploymentsJson, string.concat(srcChainKey, ".adapters.layerZero.sender"));

                LayerZeroAdapter lzAdapter = LayerZeroAdapter(lzAdapterAddress);
                lzAdapter.setPeer(lzChain.eid, bytes32(uint256(uint160(peerAddress))));
            }
        } else {
            address peerAddress = vm.parseJsonAddress(deploymentsJson, ".arbitrum_sepolia.adapters.layerZero.sender");

            address lzReceiverAddress =
                vm.parseJsonAddress(deploymentsJson, string.concat(srcChainKey, ".adapters.layerZero.receiver"));

            LayerZeroReceiver lzReceiver = LayerZeroReceiver(payable(lzReceiverAddress));
            lzReceiver.setPeer(hubNetwork.eid, bytes32(uint256(uint160(peerAddress))));
        }
    }
}
