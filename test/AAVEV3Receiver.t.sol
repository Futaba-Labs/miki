// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { AAVEV3Receiver } from "../src/examples/AAVEV3Receiver.sol";
import { ATokenMock } from "./mock/ATokenMock.sol";
import { AAVEV3PoolMock } from "./mock/AAVEV3PoolMock.sol";
import { ERC20Mock } from "./mock/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IATokenMock } from "./mock/ATokenMock.sol";
import { BridgeReceiverMock } from "./mock/BridgeReceiverMock.sol";
import { SampleAMM } from "../src/examples/SampleAMM.sol";
import { MikiReceiver } from "../src/adapters/MikiReceiver.sol";

contract AAVEV3ReceiverTest is PRBTest, StdCheats {
    address public owner;
    address[] private adapters;
    MikiReceiver public mikiReceiver;
    BridgeReceiverMock public bridgeReceiver;
    AAVEV3Receiver public aaveReceiver;
    ATokenMock public aToken;
    AAVEV3PoolMock public pool;
    ERC20Mock public erc20;
    ERC20Mock public anotherErc20;
    SampleAMM public amm;

    event TokenPoolSet(address token, address aToken, address pool);
    event Supply(address user, address token, uint256 amount, address aToken, uint256 aTokenAmount);
    event FailedMsgAndToken(
        bytes32 id,
        uint256 _srcChainId,
        address _srcAddress,
        address _token,
        address _receiver,
        uint256 _amountLD,
        bytes _message,
        string _reason
    );

    function setUp() public virtual {
        owner = msg.sender;

        erc20 = new ERC20Mock("erc20", "erc20");
        anotherErc20 = new ERC20Mock("anotherErc20", "anotherErc20");

        mikiReceiver = new MikiReceiver(owner);

        bridgeReceiver = new BridgeReceiverMock(address(mikiReceiver));
        amm = new SampleAMM(address(anotherErc20), address(erc20));
        aToken = new ATokenMock("aToken", "aToken");
        pool = new AAVEV3PoolMock(address(aToken));
        aaveReceiver = new AAVEV3Receiver(owner, address(this), address(amm), address(mikiReceiver), owner);

        erc20.mint(owner, 11_000 ether);
        anotherErc20.mint(owner, 11_000 ether);

        vm.startPrank(owner);
        adapters = [address(mikiReceiver)];
        mikiReceiver.setAdapters(adapters);
        aaveReceiver.setTokenPool(address(erc20), address(aToken), address(pool));

        IERC20(erc20).approve(address(amm), 1000 ether);
        IERC20(anotherErc20).approve(address(amm), 1000 ether);

        amm.addLiquidity(1000 ether, 1000 ether);

        vm.stopPrank();
    }

    function test_MikiReceive() public {
        vm.prank(owner);
        IERC20(erc20).transfer(address(bridgeReceiver), 1000 ether);
        vm.expectEmit(true, true, true, true);
        emit Supply(owner, address(erc20), 1000 ether, address(aToken), 1000 ether);

        bytes32 id = keccak256(abi.encodePacked(msg.sender, uint256(80_001), address(aaveReceiver), bytes("")));
        bytes memory messageWithId = abi.encode(id, bytes(""));
        bytes memory payload = abi.encode(owner, address(aaveReceiver), false, messageWithId);

        bridgeReceiver.receiveMsgWithAmount(1, owner, address(erc20), 1000 ether, payload);

        assertEq(erc20.balanceOf(owner), 9000 ether);
        assertEq(aToken.balanceOf(owner), 1000 ether);
    }

    function test_MikiReceiveWithSwap() public {
        vm.prank(owner);
        IERC20(anotherErc20).transfer(address(bridgeReceiver), 1000 ether);

        bytes32 id = keccak256(abi.encodePacked(msg.sender, uint256(80_001), address(aaveReceiver), bytes("")));
        bytes memory messageWithId = abi.encode(id, bytes(""));
        bytes memory payload = abi.encode(owner, address(aaveReceiver), false, messageWithId);

        bridgeReceiver.receiveMsgWithAmount(1, owner, address(anotherErc20), 1000 ether, payload);

        assertEq(anotherErc20.balanceOf(owner), 9000 ether);
    }

    function test_NotMikiReceiver() public {
        bytes4 selector = bytes4(keccak256("NotMikiReceiver()"));
        vm.expectRevert(selector);
        aaveReceiver.mikiReceive(1, owner, address(erc20), 100 ether, bytes(""));
    }

    function test_InvalidToken() public {
        vm.prank(owner);
        IERC20(anotherErc20).transfer(address(bridgeReceiver), 100 ether);

        bytes32 id = keccak256(abi.encodePacked(msg.sender, uint256(80_001), address(aaveReceiver), bytes("")));
        bytes memory messageWithId = abi.encode(id, bytes(""));
        bytes memory payload = abi.encode(owner, address(aaveReceiver), false, messageWithId);

        vm.expectEmit(true, true, true, true);
        emit FailedMsgAndToken(
            id, 1, owner, address(anotherErc20), address(aaveReceiver), 100 ether, bytes(""), "Unknown error"
        );

        bridgeReceiver.receiveMsgWithAmount(1, owner, address(anotherErc20), 100 ether, payload);
    }

    function test_Withdraw() public {
        vm.startPrank(owner);
        IERC20(erc20).transfer(address(bridgeReceiver), 1000 ether);
        bytes32 id = keccak256(abi.encodePacked(msg.sender, uint256(80_001), address(aaveReceiver), bytes("")));

        bytes memory messageWithId = abi.encode(id, bytes(""));
        bytes memory payload = abi.encode(owner, address(aaveReceiver), false, messageWithId);
        bridgeReceiver.receiveMsgWithAmount(1, owner, address(erc20), 1000 ether, payload);

        IATokenMock(aToken).approve(address(aaveReceiver), 500 ether);
        aaveReceiver.withdraw(address(erc20), 500 ether);
        vm.stopPrank();
        assertEq(erc20.balanceOf(owner), 9000 ether);
        assertEq(erc20.balanceOf(address(aaveReceiver)), 500 ether);
        assertEq(aToken.balanceOf(owner), 500 ether);
    }

    function test_SetTokenPool() public {
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit TokenPoolSet(address(erc20), address(aToken), address(pool));
        aaveReceiver.setTokenPool(address(erc20), address(aToken), address(pool));
        vm.stopPrank();

        assertEq(aaveReceiver.getTokenPool(address(erc20)).pool, address(pool));
        assertEq(aaveReceiver.getTokenPool(address(erc20)).aToken, address(aToken));
    }
}
