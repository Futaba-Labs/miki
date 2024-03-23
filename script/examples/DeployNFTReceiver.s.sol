// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { NFTReceiver } from "../../src/examples/NFTReceiver.sol";
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract DeployNFTReceiver is BaseScript {
    NFTReceiver public nftReceiver;
    string public uri = "ipfs://QmeuC3tFtndSF1pBTzZxUmArWiBFv3ozNhEnAPFKJp9T1E/0";
    address public mikiReceiver = 0x175EC2f76e71f7a0f28B29244bd947a40ff11642;

    function run() public broadcast {
        nftReceiver = new NFTReceiver(uri, mikiReceiver);
    }
}
