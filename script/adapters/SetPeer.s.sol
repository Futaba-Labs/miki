// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";

import { ETHTokenPool } from "../../src/pools/ETHTokenPool.sol";
import { MikiTestToken } from "../../src/adapters/MikiTestToken.sol";
import { LayerZeroAdapter } from "../../src/adapters/LayerZeroAdapter.sol";
import { LayerZeroReceiver } from "../../src/adapters/LayerZeroReceiver.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract SetPeer is BaseScript {
    Network[] public deployedNetworks =
        [networks[Chains.ArbitrumSepolia], networks[Chains.PolygonMumbai], networks[Chains.OptimismSepolia]];

    function setMikiPeer() public broadcast {
        for (uint256 i = 0; i < deployedNetworks.length; i++) {
            if (deployedNetworks[i].chainId == block.chainid) continue;
            string memory targetChainKey = _getChainKey(deployedNetworks[i].chainId);
            address peerAddress =
                vm.parseJsonAddress(deploymentsJson, string.concat(targetChainKey, ".adapters.miki.token"));

            string memory srcChainKey = _getChainKey(block.chainid);
            address mikiAddress =
                vm.parseJsonAddress(deploymentsJson, string.concat(srcChainKey, ".adapters.miki.token"));

            MikiTestToken miki = MikiTestToken(mikiAddress);
            miki.setPeer(deployedNetworks[i].eid, bytes32(uint256(uint160(peerAddress))));
        }
    }

    function setLzAdapterPeer() public broadcast {
        for (uint256 i = 0; i < deployedNetworks.length; i++) {
            if (deployedNetworks[i].chainId == block.chainid) continue;
            string memory targetChainKey = _getChainKey(deployedNetworks[i].chainId);
            address peerAddress =
                vm.parseJsonAddress(deploymentsJson, string.concat(targetChainKey, ".adapters.layerZero.sender"));

            string memory srcChainKey = _getChainKey(block.chainid);
            address lzAdapterAddress =
                vm.parseJsonAddress(deploymentsJson, string.concat(srcChainKey, ".adapters.layerZero.sender"));

            LayerZeroAdapter lzAdapter = LayerZeroAdapter(lzAdapterAddress);
            lzAdapter.setPeer(deployedNetworks[i].eid, bytes32(uint256(uint160(peerAddress))));
        }
    }
}
