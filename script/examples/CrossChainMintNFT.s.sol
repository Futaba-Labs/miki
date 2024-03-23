// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { NFTReceiver } from "../../src/examples/NFTReceiver.sol";
import { LayerZeroAdapter } from "../../src/adapters/LayerZeroAdapter.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract CrossChainMintNFT is BaseScript {
    using OptionsBuilder for bytes;

    NFTReceiver public nftReceiver = NFTReceiver(payable(0xd8f4477933a24393280cf31d086a8674eA1d19c0));
    LayerZeroAdapter public lzAdapter = LayerZeroAdapter(payable(0x80B86E002D91534F33046fBf138fEA8B832975cf));

    uint256 public dstChainId = 11_155_420;

    function run() public broadcast {
        bytes memory option = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0);

        bytes memory message = abi.encode(broadcaster);

        bytes memory params = abi.encode(option, bytes(""));
        uint256 fee =
            lzAdapter.estimateFee(broadcaster, dstChainId, address(nftReceiver), address(0), message, 0, params);

        lzAdapter.execCrossChainContractCall{ value: fee * 120 / 100 }(
            broadcaster, dstChainId, address(nftReceiver), message, fee * 120 / 100, params
        );
    }
}
