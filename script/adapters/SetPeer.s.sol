// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";

import { ETHTokenPool } from "../../src/pools/ETHTokenPool.sol";
import { MikiTestToken } from "../../src/adapters/MikiTestToken.sol";
import { LayerZeroAdapter } from "../../src/adapters/LayerZeroAdapter.sol";
import { LayerZeroReceiver } from "../../src/adapters/LayerZeroReceiver.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract SetPeer is BaseScript {
    // MikiTestToken public miki = MikiTestToken(0x587AF5e09a4e6011d5B7C38d45344792D6800898);
    MikiTestToken public miki = MikiTestToken(0x7529afb262e776620a52e143d3610299A3F0C013);
    LayerZeroAdapter public lzAdapter = LayerZeroAdapter(payable(0x80B86E002D91534F33046fBf138fEA8B832975cf));
    LayerZeroReceiver public lzReceiver = LayerZeroReceiver(payable(0x175EC2f76e71f7a0f28B29244bd947a40ff11642));

    address[] public peers = [0x7529afb262e776620a52e143d3610299A3F0C013, 0x587AF5e09a4e6011d5B7C38d45344792D6800898];

    address[] public lzAdapterPeers =
        [0x175EC2f76e71f7a0f28B29244bd947a40ff11642, 0x80B86E002D91534F33046fBf138fEA8B832975cf];

    uint32[] public eids = [40_232, 40_231];

    function run() public broadcast {
        // for (uint256 i = 0; i < peers.length; i++) {
        //     miki.setPeer(eids[i], bytes32(uint256(uint160(peers[i]))));
        // }

        // for (uint256 i = 0; i < lzAdapterPeers.length; i++) {
        //     lzAdapter.setPeer(eids[i], bytes32(uint256(uint160(lzAdapterPeers[i]))));
        // }

        for (uint256 i = 0; i < lzAdapterPeers.length; i++) {
            lzReceiver.setPeer(eids[i], bytes32(uint256(uint160(lzAdapterPeers[i]))));
        }
    }
}
