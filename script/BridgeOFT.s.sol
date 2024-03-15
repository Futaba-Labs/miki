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

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract BridgeOFT is BaseScript {
    using OptionsBuilder for bytes;

    MikiAdapter public mikiAdapter = MikiAdapter(payable(0xf4B15E2c29C7397Fdec4575DB6Ed20C9885EB28b));
    MikiTestToken public miki = MikiTestToken(0x587AF5e09a4e6011d5B7C38d45344792D6800898);

    address recepient = 0x238Ae0427004bc4bF7fc2F0d9d99F87e9E367B3D;
    uint256 dstChainId = 11_155_420;
    uint256 amount = 1 ether;
    uint256 minAmount = 1 ether;
    string greeting = "Hello, Miki!";

    function run() public broadcast {
        bytes memory option =
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0).addExecutorLzComposeOption(0, 200_000, 0);

        bytes memory message = abi.encode(greeting);

        bytes memory estimatedFeeParams = abi.encode(amount, minAmount, recepient, option);
        uint256 fee = mikiAdapter.estimateFee(dstChainId, message, estimatedFeeParams);

        IERC20(miki).approve(address(mikiAdapter), amount);
        bytes memory params = abi.encode(minAmount, option);
        mikiAdapter.execCrossChainContractCallWithAsset{ value: fee * 120 / 100 }(
            broadcaster, dstChainId, recepient, address(0), message, fee * 120 / 100, amount, params
        );
    }
}
