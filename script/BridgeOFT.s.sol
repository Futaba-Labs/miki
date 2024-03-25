// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "./Base.s.sol";

import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { MikiAdapter } from "../src/adapters/MikiAdapter.sol";
import { MikiTestToken } from "../src/adapters/MikiTestToken.sol";

import { SendParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { MessagingFee } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MikiTokenPool } from "../src/pools/MikiTokenPool.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract BridgeOFT is BaseScript {
    using OptionsBuilder for bytes;

    // MikiAdapter public mikiAdapter = MikiAdapter(payable(0x700596f9F85b7E9c7bF6a2F58134362A22873A18));
    // MikiTestToken public miki = MikiTestToken(0x587AF5e09a4e6011d5B7C38d45344792D6800898);
    // MikiTokenPool public mikiTokenPool = MikiTokenPool(payable(0x8953512400A5fde7C5730e0942f14811Fc674e0B));

    address recepient = 0x238Ae0427004bc4bF7fc2F0d9d99F87e9E367B3D;
    uint256 dstChainId = 80_001;
    uint256 amount = 1 ether;
    uint256 minAmount = 1 ether;
    string greeting = "Hello, Miki!";

    function run() public broadcast { }

    function bridgeFromTokenPool() public broadcast {
        // bytes memory option =
        //     OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0).addExecutorLzComposeOption(0, 200_000,
        // 0);

        // bytes memory message = abi.encode(greeting);

        // bytes memory params = abi.encode(minAmount, option);
        // uint256 fee =
        //     mikiAdapter.estimateFee(broadcaster, dstChainId, recepient, address(miki), message, amount, params);

        // mikiTokenPool.crossChainContractCallWithAsset{ value: fee * 120 / 100 }(
        //     dstChainId, recepient, message, fee * 120 / 100, amount, params
        // );
    }

    function bridgeFromOFT() public broadcast {
        bytes memory option = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0);

        string memory srcChainKey = _getChainKey(block.chainid);
        address mikiAddr = vm.parseJsonAddress(deploymentsJson, string.concat(srcChainKey, ".adapters.miki.token"));

        MikiTestToken miki = MikiTestToken(mikiAddr);

        Network memory network = _getNetwork(dstChainId);

        SendParam memory sendParam =
            SendParam(network.eid, bytes32(uint256(uint160(msg.sender))), amount, minAmount, option, "", "");

        MessagingFee memory msgFee = miki.quoteSend(sendParam, false);

        miki.send{ value: msgFee.nativeFee }(sendParam, msgFee, msg.sender);
    }
}
