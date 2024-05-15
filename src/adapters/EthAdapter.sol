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
    /// @dev The address of the orbiter router
    address public orbiterRouter;
    /// @dev The address of the orbiter maker
    address public orbiterMaker;

    /// @dev The address of the miki router
    address public mikiRouter;

    /// @dev The address of the layer zero adapter
    address public lzAdapter;

    /// @dev The address of the receiver
    address public receiver;

    /// @notice Mapping: chainId => identification code in Orbiter
    /// @notice ref: https://docs.orbiter.finance/orbiterfinancesbridgeprotocol#workflow
    mapping(uint256 chainId => uint16 code) public identificationCodes;

    /* ----------------------------- Events -------------------------------- */
    /**
     * @notice Event: Set identification code
     * @param chainId The chain id
     * @param code The identification code
     */
    event SetIdentificationCode(uint256 chainId, uint16 code);

    /**
     * @notice Event: Transfer miki router
     * @param sender The sender address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param amount The amount of the asset
     * @param message The message of the cross chain contract call
     */
    event TransferMikiRouter(address sender, uint256 dstChainId, address recipient, uint256 amount, bytes message);

    /* ----------------------------- Errors -------------------------------- */
    /// @notice Error: Invalid length
    error InvalidLength();

    /// @notice Error: Mismatch length
    error MismatchLength();

    /// @notice Error: Invalid code
    error InvalidCode();

    /* ----------------------------- Constructor -------------------------------- */

    /**
     * @notice Constructor
     * @param _orbiterRouter The address of the orbiter router
     * @param _mikiRouter The address of the miki router
     * @param _lzAdapter The address of the layer zero adapter
     * @param _initialOwner The address of the initial owner
     */
    constructor(
        address _orbiterRouter,
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

    /* ----------------------------- External Functions -------------------------------- */
    /**
     * @notice Execute a cross chain contract call
     * @dev Execute cross-chain contract call via LayerZero's Adapter
     * @param sender The sender address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param message The message of the cross chain contract call
     * @param fee The fee of the cross chain contract call
     * @param params The parameters of the cross chain contract call
     */
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

    /**
     * @notice Execute a cross chain contract call with asset
     * @dev Send ETH to Relayer operating in Gelato to run ETH composable bridge
     * @param sender The sender address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param message The message of the cross chain contract call
     * @param fee The fee of the cross chain contract call
     * @param amount The amount of the asset
     */
    function execCrossChainContractCallWithAsset(
        address sender,
        uint256 dstChainId,
        address recipient,
        address,
        bytes calldata message,
        uint256 fee,
        uint256 amount,
        bytes calldata
    )
        external
        payable
    {
        bytes memory _payload = abi.encode(sender, recipient, message);

        payable(mikiRouter).transfer(amount + fee);

        emit TransferMikiRouter(sender, dstChainId, recipient, amount, _payload);
    }

    /**
     * @notice Execute a cross chain transfer asset
     * @dev Send ETH to Orbiter's Maker via Orbiter Router
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param amount The amount of the asset
     */
    function execCrossChainTransferAsset(
        address,
        uint256 dstChainId,
        address recipient,
        address,
        uint256,
        uint256 amount,
        bytes calldata
    )
        external
        payable
    {
        uint16 code = identificationCodes[dstChainId];

        if (code == 0) {
            revert InvalidCode();
        }

        // Decoding results in "t={recipient}"
        IOrbiterXRouterV3(orbiterRouter).transfer{ value: amount + code }(
            orbiterMaker, abi.encodePacked(string.concat("t=0x", _stringToHex(string(abi.encodePacked(recipient)))))
        );
    }

    /**
     * @notice Estimate fee
     * @dev Estimate fee of the cross chain contract call via LayerZero's Adapter
     * @dev If LayerZero is not used, return fee as 0
     * @param sender The sender address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     * @param asset The asset address
     * @param message The message of the cross chain contract call
     * @param amount The amount of the asset
     * @param params The parameters of the cross chain contract call
     */
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

    /**
     * @notice Set identification code
     * @param chainIds The chain ids
     * @param codes The identification codes
     */
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

    /**
     * @notice Get identification code
     * @param chainId The chain id
     */
    function getIdentificationCode(uint256 chainId) external view returns (uint16) {
        return identificationCodes[chainId];
    }

    /* ----------------------------- Private Functions -------------------------------- */
    /**
     * @notice Convert string to hex
     * @param str The string
     */
    function _stringToHex(string memory str) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory hexBytes = new bytes(strBytes.length * 2);
        uint256 j = 0;
        for (uint256 i = 0; i < strBytes.length; i++) {
            uint256 hexValue = uint8(strBytes[i]);
            hexBytes[j++] = _nibbleToHex(uint8(hexValue >> 4));
            hexBytes[j++] = _nibbleToHex(uint8(hexValue & 0x0f));
        }
        return string(hexBytes);
    }

    /**
     * @notice Convert nibble to hex
     * @param nibble The nibble
     */
    function _nibbleToHex(uint8 nibble) private pure returns (bytes1) {
        if (nibble < 10) {
            return bytes1(nibble + 48);
        } else {
            return bytes1(nibble + 87);
        }
    }

    receive() external payable { }
}
