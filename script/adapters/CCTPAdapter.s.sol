// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { CCTPAdapter } from "../../src/adapters/CCTPAdapter.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CCTPAdapterScript is BaseScript {
    CCTPAdapter cctpAdapter;
    address usdc = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;
    address tokenMessanger = 0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5;
    address receipient = 0xc92FE6Db0a49C339E1D56eB23ECF6a7251aac67C;
    uint256 amount = 100_000;
    uint256 dstChainId = 84_532;

    function run() public broadcast {
        cctpAdapter = new CCTPAdapter(broadcaster, tokenMessanger, usdc);

        IERC20(usdc).approve(address(cctpAdapter), amount);

        cctpAdapter.execCrossChainTransferAsset(broadcaster, dstChainId, receipient, usdc, amount, 0, bytes(""));
    }
}
