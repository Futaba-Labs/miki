// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "./Base.s.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import { L2AssetManager } from "../src/L2AssetManager.sol";
import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { L2BridgeAdapter } from "../src/adapters/L2BridgeAdapter.sol";
import { LayerZeroAdapter } from "../src/adapters/LayerZeroAdapter.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract CrossChain is BaseScript {
    address public weth = 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73;
    address public recipient = 0x72167b4aAE65E98f328Ce612574811d23cC11Ef7; // Hello World contract
    uint256 public dstCahinId = 11_155_111;
    uint256 public amount = 0.01 ether;
    ETHTokenPool public ethTokenPool = ETHTokenPool(0x0942fbCe0901f98c8B0CddB7Dc09eb1022311666);
    LayerZeroAdapter public lzAdapter = LayerZeroAdapter(0xc5aB2b2875e43BD23dc5824F2430daCC84d6FD70);

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

        // calc fee
        bytes memory params = abi.encode(broadcaster, true);
        bytes memory message = abi.encodeWithSignature("greet(string)", "Hello, world!!");
        uint256 fee = lzAdapter.estimateFee(dstCahinId, message, params);

        // send bridge
        // ethTokenPool.crossChainTransferAsset(dstCahinId, broadcaster, fee, amount, params);

        // send message with asset
        ethTokenPool.crossChainContractCallWithAsset(dstCahinId, recipient, message, fee, amount, params);
    }
}
