// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { CCTPAdapter } from "../../src/adapters/CCTPAdapter.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CCTPAdapterScript is BaseScript {
    CCTPAdapter cctpAdapter;

    address constant usdc = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;
    address constant tokenMessanger = 0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5; // Base Sepolia
    address constant cctpReceiver = 0x38404A0Ab62E635b8d675aFca83f8e29029B81Cd;
    address constant receipient = 0x39338FD37f41BabC04e119332198346C0EB31022;
    uint256 constant amount = 100_000;
    uint256 constant dstChainId = 84_532; // Base Sepolia

    function run() public broadcast {
        deploy();
        execCrossChainTransferAsset();
    }

    function deploy() public broadcast {
        cctpAdapter = new CCTPAdapter(broadcaster, tokenMessanger, usdc);
        _setMintRecipientsBaseSepolia();
    }

    function execCrossChainTransferAsset() public broadcast {
        IERC20(usdc).approve(address(cctpAdapter), amount);
        cctpAdapter.execCrossChainTransferAsset(broadcaster, dstChainId, receipient, usdc, amount, 0, bytes(""));
    }

    function _setMintRecipientsBaseSepolia() internal {
        uint32[] memory chainIds = new uint32[](1);
        chainIds[0] = 6;
        address[] memory recipients = new address[](1);
        recipients[0] = cctpReceiver;
        cctpAdapter.setMintRecipients(chainIds, recipients);
    }
}
