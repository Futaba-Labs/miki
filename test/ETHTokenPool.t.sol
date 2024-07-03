// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { L2AssetManager } from "../src/L2AssetManager.sol";
import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { TokenPoolBase } from "../src/pools/TokenPoolBase.sol";
import { BridgeAdapterMock } from "./mock/BridgeAdapterMock.sol";
import { BridgeReceiverMock } from "./mock/BridgeReceiverMock.sol";
import { SampleMikiReceiver } from "../src/examples/SampleMikiReceiver.sol";
import { MikiReceiver } from "../src/adapters/MikiReceiver.sol";

contract ETHTokenPoolTest is PRBTest, StdCheats {
    bytes constant MESSAGE = abi.encode("Hello, world!");
    address public owner;
    address public underlyingToken;
    ProxyAdmin public mikiProxyAdmin;
    L2AssetManager public l2AssetManager;
    ETHTokenPool public ethTokenPool;
    BridgeAdapterMock public bridgeAdapterMock;
    BridgeReceiverMock public bridgeReceiverMock;
    SampleMikiReceiver public sampleMikiReceiver;
    MikiReceiver public mikiReceiver;

    event Greeting(string message);

    /// @dev A function invoked before each test case is run.

    function setUp() public virtual {
        // Instantiate the contract-under-test.
        owner = msg.sender;
        console2.log(owner);

        underlyingToken = address(this);
        L2AssetManager l2AssetManagerImplementation = new L2AssetManager();
        l2AssetManager = L2AssetManager(
            address(
                new TransparentUpgradeableProxy(
                    address(l2AssetManagerImplementation),
                    owner,
                    abi.encodeWithSelector(L2AssetManager.initialize.selector, owner)
                )
            )
        );
        ETHTokenPool ethTokenPoolImpl = new ETHTokenPool(address(l2AssetManager), owner);
        ethTokenPool = ETHTokenPool(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(ethTokenPoolImpl),
                        owner,
                        abi.encodeWithSelector(TokenPoolBase.initialize.selector, owner, underlyingToken)
                    )
                )
            )
        );

        // Set the native token pool.
        vm.prank(owner);
        l2AssetManager.setNativeTokenPool(address(ethTokenPool));

        // Instantiate the BridgeAdapterMock.
        bridgeAdapterMock = new BridgeAdapterMock();

        // Set the bridge adapter.
        vm.prank(owner);
        ethTokenPool.setBridgeAdapter(1, address(bridgeAdapterMock));

        // Instantiate the MikiReceiver.
        mikiReceiver = new MikiReceiver(owner);

        // Instantiate the BridgeReceiverMock.
        bridgeReceiverMock = new BridgeReceiverMock(address(mikiReceiver));

        // Instantiate the HelloWorld contract.
        sampleMikiReceiver = new SampleMikiReceiver();

        // Set the miki receiver.
        address[] memory adapters = new address[](1);
        adapters[0] = address(bridgeReceiverMock);
        vm.prank(owner);
        mikiReceiver.setAdapters(adapters);
    }

    function test_CrossChainContractCall() external {
        _deposit();
        uint256 dstChainId = 1;
        address recipient = address(sampleMikiReceiver);
        uint256 fee = 0.01 ether;
        bytes memory params = abi.encode(true);
        ethTokenPool.crossChainContractCall(dstChainId, recipient, MESSAGE, fee, params);
        uint256 balance = l2AssetManager.getDeposit(address(ethTokenPool), address(this));
        assertEq(balance, 1 ether - fee);

        bytes32 id = keccak256(abi.encodePacked(msg.sender, dstChainId, recipient, MESSAGE));
        bytes memory messageWithId = abi.encode(id, MESSAGE);

        // receive the msg
        bytes memory payload = abi.encode(address(ethTokenPool), recipient, messageWithId);
        vm.expectEmit(true, true, true, true);
        emit Greeting("Hello, world!");
        bridgeReceiverMock.receiveMsg(1, address(this), payload);
    }

    function test_CrossChainContractCallWithAsset() external {
        _deposit();
        uint256 dstChainId = 1;
        address recipient = address(sampleMikiReceiver);
        uint256 fee = 0.01 ether;
        uint256 amount = 0.5 ether;
        bytes memory params = abi.encode(true);
        ethTokenPool.crossChainContractCallWithAsset(dstChainId, recipient, MESSAGE, fee, amount, params);
        uint256 balance = l2AssetManager.getDeposit(address(ethTokenPool), address(this));
        assertEq(balance, 1 ether - fee - amount);

        bytes32 id = keccak256(abi.encodePacked(msg.sender, dstChainId, recipient, MESSAGE));
        bytes memory messageWithId = abi.encode(id, MESSAGE);

        // receive the msg and asset
        bytes memory payload = abi.encode(address(ethTokenPool), recipient, true, messageWithId);
        vm.expectEmit(true, true, true, true);
        emit Greeting("Hello, world!");
        bridgeReceiverMock.receiveMsgWithAmount{ value: amount }(1, address(this), address(0), amount, payload);
        assertEq(address(sampleMikiReceiver).balance, 0.5 ether);
    }

    function test_CrossChainTransferAsset() external {
        _deposit();
        uint256 dstChainId = 1;
        address recipient = address(this);
        uint256 fee = 0.01 ether;
        uint256 amount = 0.5 ether;
        bytes memory params = abi.encode(true);
        ethTokenPool.crossChainTransferAsset(dstChainId, recipient, fee, amount, params);
        uint256 balance = l2AssetManager.getDeposit(address(ethTokenPool), address(this));
        assertEq(balance, 1 ether - fee - amount);
    }

    function test_CrossChainContractCallWithAssetToL1() external {
        // TODO Implement this test.
    }

    function test_NotSupportedChain() external {
        bytes4 selector = bytes4(keccak256("NotSupportedChain()"));
        vm.expectRevert(selector);
        ethTokenPool.crossChainContractCall(2, address(this), "", 0, bytes(""));
    }

    function test_InsufficientAmount() external {
        _deposit();
        bytes4 selector = bytes4(keccak256("InsufficientAmount()"));
        vm.expectRevert(selector);
        ethTokenPool.crossChainTransferAsset(1, address(this), 0.01 ether, 1 ether, bytes(""));
    }

    function test_InsufficientFee() external {
        _deposit();
        bytes4 selector = bytes4(keccak256("InsufficientFee()"));
        vm.expectRevert(selector);
        ethTokenPool.crossChainContractCall(1, address(this), "", 5000, bytes(""));
    }

    function test_DepositOnlyL2AssetManager() external {
        // Deposit 1 ETH to the native token pool.
        bytes4 selector = bytes4(keccak256("OnlyL2AssetManager()"));
        vm.expectRevert(selector);
        ethTokenPool.deposit{ value: 1 ether }(1 ether);
    }

    function test_WithdrawOnlyL2AssetManager() external {
        bytes4 selector = bytes4(keccak256("OnlyL2AssetManager()"));
        vm.expectRevert(selector);
        ethTokenPool.withdraw(address(this), 1 ether);
    }

    function test_SetBridgeAdapter() external {
        vm.prank(owner);
        ethTokenPool.setBridgeAdapter(1, address(bridgeAdapterMock));
        assertEq(ethTokenPool.bridgeAdapters(1), address(bridgeAdapterMock));
    }

    function test_SetBridgeAdapterOnlyOwner() external {
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, address(this)));
        ethTokenPool.setBridgeAdapter(1, address(this));
    }

    function test_AddBatchesOnlyL2AssetManager() external {
        bytes4 selector = bytes4(keccak256("OnlyL2AssetManager()"));
        vm.expectRevert(selector);
        ethTokenPool.addBatches(address(this), 1 ether);
    }

    function _deposit() internal {
        l2AssetManager.depositETH{ value: 1 ether }(1 ether);
    }
}
