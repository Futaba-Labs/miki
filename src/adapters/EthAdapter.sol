// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import { IOrbiterXRouterV3 } from "../interfaces/IOrbiterXRouterV3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ILayerZeroAdapter } from "../interfaces/ILayerZeroAdapter.sol";

/**
 * @title EthAdapter
 * @notice This is a contract to perform Cross-chain Transfer of ETH or messaging with ETH as gas fee.
 */
contract EthAdapter is IL2BridgeAdapter, Ownable {
    /* ----------------------------- Storage -------------------------------- */
    address public orbiterRouter;
    address public mikiRouter;
    address public lzAdapter;
    address public receiver;

    mapping(uint256 chainId => uint16 code) public identificationCodes;

    /* ----------------------------- Events -------------------------------- */
    event SetIdentificationCode(uint256 chainId, uint16 code);
    event TransferMikiRouter(address sender, uint256 dstChainId, address recipient, uint256 amount, bytes message);

    /* ----------------------------- Errors -------------------------------- */
    error InvalidLength();
    error MismatchLength();
    error InvalidCode();

    /* ----------------------------- Constructor -------------------------------- */

    constructor(
        address payable _orbiterRouter,
        address payable _mikiRouter,
        address _lzAdapter,
        address _initialOwner
    )
        Ownable(_initialOwner)
    {
        orbiterRouter = _orbiterRouter;
        mikiRouter = _mikiRouter;
        lzAdapter = _lzAdapter;
    }

    function execCrossChainContractCall(
        address sender,
        uint256 dstChainId,
        address recipient,
        bytes calldata message,
        uint256 fee,
        bytes calldata params
    )
        external
        payable
    {
        ILayerZeroAdapter(lzAdapter).lzSend{ value: fee }(sender, dstChainId, recipient, message, fee, params);
    }

    function execCrossChainContractCallWithAsset(
        address sender,
        uint256 dstChainId,
        address recipient,
        address asset,
        bytes calldata message,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable
    {
        bytes memory _payload = abi.encode(sender, recipient, message);

        payable(mikiRouter).transfer(amount + fee);

        emit TransferMikiRouter(sender, dstChainId, recipient, amount, _payload);
    }

    function execCrossChainTransferAsset(
        address sender,
        uint256 dstChainId,
        address recipient,
        address asset,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable
    {
        // uint16 code = identificationCodes[dstChainId];

        // if (code == 0) {
        //     revert InvalidCode();
        // }

        // uint256 totalAmount = amount + code;

        // address[] memory recipients = new address[](1);
        // recipients[0] = recipient;
        // uint256[] memory amounts = new uint256[](1);
        // amounts[0] = totalAmount;

        payable(mikiRouter).transfer(amount + fee);

        emit TransferMikiRouter(sender, dstChainId, recipient, amount, bytes(""));
    }

    function estimateFee(
        address sender,
        uint256 dstChainId,
        address recipient,
        address asset,
        bytes calldata message,
        uint256 amount,
        bytes calldata params
    )
        external
        view
        returns (uint256)
    {
        if (params.length > 0) {
            return
                ILayerZeroAdapter(lzAdapter).estimateFee(sender, dstChainId, recipient, asset, message, amount, params);
        }

        return 0;
    }

    function setIdentificationCodes(uint256[] memory chainIds, uint16[] memory codes) external onlyOwner {
        uint256 chainIdLength = chainIds.length;
        if (chainIdLength != codes.length) {
            revert MismatchLength();
        }

        if (chainIdLength == 0) {
            revert InvalidLength();
        }

        for (uint256 i; i < chainIdLength;) {
            identificationCodes[chainIds[i]] = codes[i];

            emit SetIdentificationCode(chainIds[i], codes[i]);

            unchecked {
                i++;
            }
        }
    }

    function getIdentificationCode(uint256 chainId) external view returns (uint16) {
        return identificationCodes[chainId];
    }

    receive() external payable { }
}
