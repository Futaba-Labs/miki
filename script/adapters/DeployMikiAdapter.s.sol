// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";

import { MikiAdapter } from "../../src/adapters/MikiAdapter.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployMikiAdapter is BaseScript {
    address public mikiToken = 0x587AF5e09a4e6011d5B7C38d45344792D6800898;
    MikiAdapter public mikiAdapter;
    uint256[] public chainIds = [11_155_420, 421_614];
    uint32[] public eids = [40_232, 40_231];
    address[] public receivers =
        [0x062b29298A670Ffc5a7F8b6030aF858E701Dd20f, 0x062b29298A670Ffc5a7F8b6030aF858E701Dd20f];

    function run() public broadcast {
        mikiAdapter = new MikiAdapter(mikiToken, broadcaster);

        mikiAdapter.setEids(chainIds, eids);

        mikiAdapter.setReceivers(chainIds, receivers);
    }
}
