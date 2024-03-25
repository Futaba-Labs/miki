// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { NFTReceiver } from "../src/examples/NFTReceiver.sol";
import { BridgeReceiverMock } from "./mock/BridgeReceiverMock.sol";

contract NFTReceiverTest is PRBTest, StdCheats {
    address public owner;
    string public tokenURI = "ipfs://QmeuC3tFtndSF1pBTzZxUmArWiBFv3ozNhEnAPFKJp9T1E/0";
    NFTReceiver public nftReceiver;
    BridgeReceiverMock public bridgeReceiver;

    event MikiNFTMinted(address to, uint256 tokenId);

    function setUp() public virtual {
        owner = msg.sender;
        bridgeReceiver = new BridgeReceiverMock();
        nftReceiver = new NFTReceiver(tokenURI, address(bridgeReceiver));
    }

    function test_mikiReceiveMsg() public {
        bytes memory message = abi.encode(msg.sender, address(nftReceiver), abi.encode(msg.sender));
        vm.expectEmit(true, true, true, true);
        emit MikiNFTMinted(msg.sender, 0);
        bridgeReceiver.receiveMsg(1, msg.sender, message);

        assertEq(nftReceiver.ownerOf(0), msg.sender);
    }

    function test_mikiReceiveMsg_notMikiReceiver() public {
        bytes memory message = abi.encode(msg.sender);
        bytes4 selector = bytes4(keccak256("NotMikiReceiver()"));
        vm.expectRevert(selector);
        nftReceiver.mikiReceiveMsg(1, msg.sender, message);
    }
}
