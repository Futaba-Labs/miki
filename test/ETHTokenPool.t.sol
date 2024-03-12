// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { L2AssetManager } from "../src/L2AssetManager.sol";
import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { BridgeAdapterMock } from "./mock/BridgeAdapterMock.sol";
import { BridgeReceiverMock } from "./mock/BridgeReceiverMock.sol";
import { HelloWorld } from "../src/examples/HelloWorld.sol";

contract ETHTokenPoolTest is PRBTest, StdCheats {
    bytes4 private constant SELECTOR = bytes4(keccak256("greet(string)"));
    bytes private ENCODED_SELECTOR = abi.encodeWithSelector(SELECTOR, "Hello, world!");
    address public owner;
    address public underlyingToken;
    ProxyAdmin public mikiProxyAdmin;
    L2AssetManager public l2AssetManager;
    ETHTokenPool public ethTokenPool;
    BridgeAdapterMock public bridgeAdapterMock;
    BridgeReceiverMock public bridgeReceiverMock;
    HelloWorld public helloWorld;

    /// @dev A function invoked before each test case is run.

    function setUp() public virtual {
        // Instantiate the contract-under-test.
        owner = msg.sender;
        underlyingToken = address(this);
        mikiProxyAdmin = new ProxyAdmin(owner);
        L2AssetManager l2AssetManagerImplementation = new L2AssetManager();
        l2AssetManager = L2AssetManager(
            address(
                new TransparentUpgradeableProxy(
                    address(l2AssetManagerImplementation),
                    address(mikiProxyAdmin),
                    abi.encodeWithSelector(L2AssetManager.initialize.selector, owner)
                )
            )
        );
        ethTokenPool = new ETHTokenPool(owner, address(l2AssetManager), owner, underlyingToken);

        // Set the native token pool.
        vm.prank(owner);
        l2AssetManager.setNativeTokenPool(address(ethTokenPool));

        // Instantiate the BridgeAdapterMock.
        bridgeAdapterMock = new BridgeAdapterMock();

        // Set the bridge adapter.
        vm.prank(owner);
        ethTokenPool.setBridgeAdapter(1, address(bridgeAdapterMock));

        // Instantiate the BridgeReceiverMock.
        bridgeReceiverMock = new BridgeReceiverMock();

        // Instantiate the HelloWorld contract.
        helloWorld = new HelloWorld();
    }

    function test_CrossChainContractCall() external {
        _deposit();
        uint256 dstChainId = 1;
        address recipient = address(this);
        uint256 fee = 0.01 ether;
        bytes memory params = bytes("");
        ethTokenPool.crossChainContractCall(dstChainId, recipient, ENCODED_SELECTOR, fee, params);
        uint256 balance = l2AssetManager.getDeposit(address(ethTokenPool), address(this));
        assertEq(balance, 1 ether - fee);
    }

    function test_CrossChainContractCallWithAsset() external {
        _deposit();
        uint256 dstChainId = 1;
        address recipient = address(helloWorld);
        uint256 fee = 0.01 ether;
        uint256 amount = 0.5 ether;
        bytes memory params = bytes("");
        ethTokenPool.crossChainContractCallWithAsset(dstChainId, recipient, ENCODED_SELECTOR, fee, amount, params);
        uint256 balance = l2AssetManager.getDeposit(address(ethTokenPool), address(this));
        assertEq(balance, 1 ether - fee - amount);

        // receive the msg and asset
        bytes memory payload = abi.encode(recipient, true, ENCODED_SELECTOR);
        address(bridgeReceiverMock).call{ value: amount }("");
        bridgeReceiverMock.receiveMsgWithAmount(1, address(this), underlyingToken, amount, payload);
    }

    function test_CrossChainTransferAsset() external {
        _deposit();
        uint256 dstChainId = 1;
        address recipient = address(this);
        uint256 fee = 0.01 ether;
        uint256 amount = 0.5 ether;
        bytes memory params = bytes("");
        ethTokenPool.crossChainTransferAsset(dstChainId, recipient, fee, amount, params);
        uint256 balance = l2AssetManager.getDeposit(address(ethTokenPool), address(this));
        assertEq(balance, 1 ether - fee - amount);
    }

    function test_CrossChainContractCallWithAssetToL1() external {
        // TODO Implement this test.
    }

    function test_NotSupportedChain() external {
        bytes4 selector = bytes4(keccak256("NotSupportedChain()"));
        console2.logBytes4(bytes4(keccak256("DisabledRoute()")));
        console2.logBytes4(bytes4(keccak256("InvalidQuoteTimestamp()")));
        console2.logBytes4(bytes4(keccak256("InvalidFillDeadline()")));
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
