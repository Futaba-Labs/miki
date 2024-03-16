// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "./Base.s.sol";

import { L2AssetManager } from "../src/L2AssetManager.sol";
import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { L2BridgeAdapter } from "../src/adapters/L2BridgeAdapter.sol";
import { LayerZeroAdapter } from "../src/adapters/LayerZeroAdapter.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract CrossChain is BaseScript {
    address public weth = 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73;
    address public recipient = 0x90B270fE5b2c06385c50Ffdf5Cc5b04Dbb4C934d; // Hello World contract
    uint256 public dstCahinId = 11_155_420;
    uint256 public amount = 0.01 ether;
    ETHTokenPool public ethTokenPool = ETHTokenPool(payable(0x02f70133DA3f51D878224C967f9677EaEf285D47));
    LayerZeroAdapter public lzAdapter = LayerZeroAdapter(0xb329B4a3D0E85E52d6fb33e4Ac435C7F34F5cA70);

    function run() public broadcast {
        // string memory rawJson;
        // {
        //     string[] memory curlInputs = new string[](5);
        //     curlInputs[0] = "curl";
        //     // arbitrum to optimism (ETH)
        //     curlInputs[1] = string(
        //         "https://across.to/api/suggested-fees?token=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1&"
        //         "destinationChainId=10&amount=10000000000000000"
        //     );
        //     curlInputs[2] = "-o";
        //     curlInputs[3] = "fee.json";
        //     curlInputs[4] = "--silent";

        //     vm.ffi(curlInputs);

        //     rawJson = vm.readFile("fee.json");
        // }
        // uint256 totalFee = vm.parseJsonUint(rawJson, ".totalRelayFee.total");
        // uint32 timestmap = uint32(vm.parseJsonUint(rawJson, ".timestamp"));

        // bytes memory params = abi.encode(timestmap);

        // calc fee by LZ
        bytes memory params = abi.encode(broadcaster, true, false);
        bytes memory message = abi.encodeWithSignature("greet(string)", "Hello, world!!");
        uint256 fee = lzAdapter.estimateFee(broadcaster, dstCahinId, recipient, weth, message, amount, params);

        // calc fee by Axelar
        // string[] memory inputs = new string[](2);
        // inputs[0] = "node";
        // inputs[1] = "./helpers/fetch_axelar_fee.js";
        // bytes memory encodedFee = vm.ffi(inputs);
        // uint256 fee = abi.decode(encodedFee, (uint256));

        // send bridge
        // ethTokenPool.crossChainTransferAsset(dstCahinId, broadcaster, fee, amount, params);

        // send message with asset
        // ethTokenPool.crossChainContractCallWithAsset(dstCahinId, recipient, message, fee, amount, bytes(""));

        // send message without asset
        ethTokenPool.crossChainContractCall(dstCahinId, recipient, message, fee, params);
    }
}
