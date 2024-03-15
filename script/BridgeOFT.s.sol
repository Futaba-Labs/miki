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

    MikiAdapter public mikiAdapter = MikiAdapter(payable(0xe860D31Cc6154C9D9505919db72c10F3B2814aFa));
    MikiTestToken public miki = MikiTestToken(0x587AF5e09a4e6011d5B7C38d45344792D6800898);

    uint256 dstChainId = 11_155_420;
    uint256 amount = 1 ether;
    uint256 minAmount = 1 ether;

    function run() public broadcast {
        bytes memory option = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0);

        bytes memory estimatedFeeParams = abi.encode(amount, minAmount, broadcaster, option);
        uint256 fee = mikiAdapter.estimateFee(dstChainId, "", estimatedFeeParams);

        IERC20(miki).approve(address(mikiAdapter), amount);
        bytes memory params = abi.encode(minAmount, option);
        mikiAdapter.execCrossChainTransferAsset{ value: fee }(
            broadcaster, dstChainId, broadcaster, address(0), amount, fee, params
        );
    }
}
