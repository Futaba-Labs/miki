// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { CCTPAdapter } from "../../src/adapters/CCTPAdapter.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ExecuteCCTPAdapter is BaseScript {
    address constant usdc = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;
    address constant deployedCCTPAdapter = 0x330F25c20621dE38132516dcC9C7C49982B37A23;
    address constant cctpReceiver = 0x38404A0Ab62E635b8d675aFca83f8e29029B81Cd;

    CCTPAdapter cctpAdapter = CCTPAdapter(deployedCCTPAdapter);

    address constant receipient = 0x39338FD37f41BabC04e119332198346C0EB31022;
    uint256 constant amount = 100_000;
    uint256 constant dstChainId = 84_532; // Base Sepolia

    function run() external {
        vm.startBroadcast();

        // _setMintRecipientsBaseSepolia();

        IERC20(usdc).approve(address(cctpAdapter), amount);
        cctpAdapter.execCrossChainTransferAsset(broadcaster, dstChainId, receipient, usdc, amount, 0, bytes(""));

        vm.stopBroadcast();
    }

    function _setMintRecipientsBaseSepolia() internal {
        uint32[] memory chainIds = new uint32[](1);
        chainIds[0] = 6;
        address[] memory recipients = new address[](1);
        recipients[0] = cctpReceiver;
        cctpAdapter.setMintRecipients(chainIds, recipients);
    }
}
