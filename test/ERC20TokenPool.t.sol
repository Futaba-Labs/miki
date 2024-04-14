// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { L2AssetManager } from "../src/L2AssetManager.sol";
import { BridgeAdapterMock } from "./mock/BridgeAdapterMock.sol";
import { BridgeReceiverMock } from "./mock/BridgeReceiverMock.sol";
import { SampleMikiReceiver } from "../src/examples/SampleMikiReceiver.sol";
import { ERC20TokenPoolMock } from "./mock/ERC20TokenPoolMock.sol";
import { ERC20Mock } from "./mock/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MikiReceiver } from "../src/adapters/MikiReceiver.sol";

contract ERC20TokenPool is PRBTest, StdCheats {
    bytes constant MESSAGE = abi.encode("Hello, world!");
    address public owner;
    address public underlyingToken;
    address[] public tokenPools;
    bool[] public whitelists = [true];
    ProxyAdmin public mikiProxyAdmin;
    L2AssetManager public l2AssetManager;
    ERC20TokenPoolMock public erc20TokenPool;
    BridgeAdapterMock public bridgeAdapterMock;
    BridgeReceiverMock public bridgeReceiverMock;
    SampleMikiReceiver public sampleMikiReceiver;
    MikiReceiver public mikiReceiver;

    event Greeting(string message);
    event Received(address sender, address token, uint256 amount, bytes message);

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
        ERC20Mock erc20 = new ERC20Mock("Test", "TEST");
        erc20.mint(address(this), 100 ether);
        underlyingToken = address(erc20);
        ERC20TokenPoolMock erc20TokenPoolImpl = new ERC20TokenPoolMock(address(l2AssetManager), underlyingToken, owner);
        erc20TokenPool = ERC20TokenPoolMock(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(erc20TokenPoolImpl),
                        address(mikiProxyAdmin),
                        abi.encodeWithSelector(ERC20TokenPoolMock.initialize.selector, owner, underlyingToken)
                    )
                )
            )
        );

        // Set the erc20 token pool.
        vm.prank(owner);
        tokenPools.push(address(erc20TokenPool));
        l2AssetManager.setTokenPoolWhitelists(tokenPools, whitelists);

        // Instantiate the BridgeAdapterMock.
        bridgeAdapterMock = new BridgeAdapterMock();

        // Set the bridge adapter.
        vm.prank(owner);
        erc20TokenPool.setBridgeAdapter(1, address(bridgeAdapterMock));

        // Instantiate the MikiReceiver.
        mikiReceiver = new MikiReceiver(owner);

        // Instantiate the BridgeReceiverMock.
        bridgeReceiverMock = new BridgeReceiverMock(address(mikiReceiver));

        // Instantiate the HelloWorld contract.
        sampleMikiReceiver = new SampleMikiReceiver();

        // set the miki receiver
        address[] memory adapters = new address[](1);
        adapters[0] = address(mikiReceiver);
        vm.prank(owner);
        mikiReceiver.setAdapters(adapters);
    }

    function test_CrossChainContractCallWithAsset() external {
        _deposit();
        uint256 dstChainId = 1;
        address recipient = address(sampleMikiReceiver);
        uint256 fee = 0.01 ether;
        uint256 amount = 0.5 ether;
        bytes memory params = abi.encode(false);
        erc20TokenPool.crossChainContractCallWithAsset{ value: fee }(
            dstChainId, recipient, MESSAGE, fee, amount, params
        );
        uint256 balance = l2AssetManager.getDeposit(address(erc20TokenPool), address(this));
        assertEq(balance, 1 ether - amount);

        // receive the msg and asset
        bytes memory payload = abi.encode(address(erc20TokenPool), recipient, false, MESSAGE);
        IERC20(underlyingToken).transfer(address(bridgeReceiverMock), amount);
        vm.expectEmit(true, true, true, true);
        emit Greeting("Hello, world!");
        emit Received(address(this), underlyingToken, amount, MESSAGE);
        bridgeReceiverMock.receiveMsgWithAmount(1, address(this), underlyingToken, amount, payload);
        assertEq(IERC20(underlyingToken).balanceOf(recipient), 0.5 ether);
    }

    function test_CrossChainTransferAsset() external {
        _deposit();
        uint256 dstChainId = 1;
        address recipient = address(this);
        uint256 fee = 0.01 ether;
        uint256 amount = 0.5 ether;
        bytes memory params = abi.encode(false);
        erc20TokenPool.crossChainTransferAsset{ value: fee }(dstChainId, recipient, fee, amount, params);
        uint256 balance = l2AssetManager.getDeposit(address(erc20TokenPool), address(this));
        assertEq(balance, 1 ether - amount);
    }

    function test_CrossChainContractCallWithAssetToL1() external {
        // TODO Implement this test.
    }

    function test_NotSupportedChain() external {
        _deposit();
        uint256 fee = 0.01 ether;
        bytes4 selector = bytes4(keccak256("NotSupportedChain()"));

        vm.expectRevert(selector);
        erc20TokenPool.crossChainTransferAsset{ value: fee }(2, address(this), fee, 1 ether, bytes(""));
    }

    function test_InsufficientAmount() external {
        _deposit();
        uint256 fee = 0.01 ether;
        bytes4 selector = bytes4(keccak256("InsufficientAmount()"));
        vm.expectRevert(selector);
        erc20TokenPool.crossChainTransferAsset{ value: fee }(1, address(this), fee, 2 ether, bytes(""));
    }

    function test_InsufficientFee() external {
        _deposit();
        uint256 fee = 0;
        bytes4 selector = bytes4(keccak256("InsufficientFee()"));
        vm.expectRevert(selector);
        erc20TokenPool.crossChainTransferAsset{ value: fee }(1, address(this), fee, 0.5 ether, bytes(""));
    }

    function test_DepositOnlyL2AssetManager() external {
        // Deposit 1 ETH to the native token pool.
        bytes4 selector = bytes4(keccak256("OnlyL2AssetManager()"));
        vm.expectRevert(selector);
        erc20TokenPool.deposit{ value: 1 ether }(1 ether);
    }

    function test_WithdrawOnlyL2AssetManager() external {
        bytes4 selector = bytes4(keccak256("OnlyL2AssetManager()"));
        vm.expectRevert(selector);
        erc20TokenPool.withdraw(address(this), 1 ether);
    }

    function test_SetBridgeAdapter() external {
        vm.prank(owner);
        erc20TokenPool.setBridgeAdapter(1, address(bridgeAdapterMock));
        assertEq(erc20TokenPool.bridgeAdapters(1), address(bridgeAdapterMock));
    }

    function test_SetBridgeAdapterOnlyOwner() external {
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, address(this)));
        erc20TokenPool.setBridgeAdapter(1, address(this));
    }

    function test_AddBatchesOnlyL2AssetManager() external {
        bytes4 selector = bytes4(keccak256("OnlyL2AssetManager()"));
        vm.expectRevert(selector);
        erc20TokenPool.addBatches(address(this), 1 ether);
    }

    function _deposit() internal {
        IERC20(underlyingToken).approve(address(l2AssetManager), 1 ether);
        l2AssetManager.deposit(underlyingToken, address(erc20TokenPool), 1 ether);
    }
}
