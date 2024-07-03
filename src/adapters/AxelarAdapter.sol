// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { IAxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import { IAxelarGateway } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract AxelarAdapter is IL2BridgeAdapter, AxelarExecutable, Ownable {
    /* ----------------------------- Storage -------------------------------- */
    address public axelarGasService;

    mapping(uint256 => string) public chainIdToDomain;
    mapping(uint256 => string) public chainIdToReceiver;

    /* ----------------------------- Events -------------------------------- */

    event SetChainIdToDomain(uint256 chainId, string domain);

    /* ----------------------------- Errors -------------------------------- */
    error InvalidLength();
    error MismatchedLength();

    /* ----------------------------- Constructor -------------------------------- */

    constructor(
        address _initialOwner,
        address _axelerGateway,
        address _axealrGasService
    )
        AxelarExecutable(_axelerGateway)
        Ownable(_initialOwner)
    {
        axelarGasService = _axealrGasService;
    }

    function execCrossChainContractCall(
        address sender,
        uint256 dstChainId,
        address recipient,
        bytes calldata message,
        uint256 fee,
        bytes calldata
    )
        external
        payable
    {
        bytes memory payload = abi.encode(sender, recipient, message);
        string memory dstChainDomain = chainIdToDomain[dstChainId];
        string memory destinationAddress = chainIdToReceiver[dstChainId];

        IAxelarGasService(axelarGasService).payNativeGasForContractCall{ value: fee }(
            address(this), dstChainDomain, destinationAddress, payload, msg.sender
        );
        gateway.callContract(dstChainDomain, destinationAddress, payload);
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
    { }

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
    { }

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
        return 0;
    }

    function setChainIdToDomains(uint256[] calldata chainId, string[] calldata domain) external onlyOwner {
        if (chainId.length == 0 || domain.length == 0) {
            revert InvalidLength();
        }

        if (chainId.length != domain.length) {
            revert MismatchedLength();
        }

        for (uint256 i; i < chainId.length; i++) {
            chainIdToDomain[chainId[i]] = domain[i];
        }
    }

    function setChainIdToReceivers(uint256[] calldata chainId, address[] calldata receiver) external onlyOwner {
        if (chainId.length == 0 || receiver.length == 0) {
            revert InvalidLength();
        }

        if (chainId.length != receiver.length) {
            revert MismatchedLength();
        }

        for (uint256 i; i < chainId.length; i++) {
            chainIdToReceiver[chainId[i]] = _addressToString(receiver[i]);
        }
    }

    /* ----------------------------- Internal functions -------------------------------- */
    function _addressToString(address _addr) internal pure returns (string memory) {
        return Strings.toHexString(uint160(_addr), 20);
    }
}
