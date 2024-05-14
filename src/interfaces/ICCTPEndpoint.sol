// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface ICCTPEndpoint {
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _cctpPaymentAddress,
        bytes calldata _adapterParams
    )
        external
        payable;

    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInCCTP, // TODO: fix this to actual token
        bytes calldata _adapterParam
    )
        external
        view
        returns (uint256 nativeFee, uint256 cctpFee);
}
