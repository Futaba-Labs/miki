// SPDX-License-Identifier: MIT
pragma solidity >=0.8.23 <0.9.0;

import { Script } from "forge-std/src/Script.sol";

abstract contract BaseScript is Script {
    /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
    string internal constant TEST_MNEMONIC = "test test test test test test test test test test test test";

    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant ZERO_SALT = bytes32(0);

    /// @dev The address of the transaction broadcaster.
    address internal broadcaster;

    /// @dev Used to derive the broadcaster's address if $ETH_FROM is not defined.
    string internal mnemonic;

    string internal deploymentPath = "constants/deployment.json";
    string internal deploymentsJson = vm.readFile(deploymentPath);

    mapping(Chains chains => Network network) internal networks;

    Chains[] internal deployedChains =
        [Chains.ArbitrumSepolia, Chains.OptimismSepolia, Chains.PolygonAmoy, Chains.BaseSepolia];

    enum Chains {
        ArbitrumSepolia,
        OptimismSepolia,
        PolygonAmoy,
        BaseSepolia
    }

    struct Network {
        string name;
        uint256 chainId;
        uint32 eid;
    }

    /// @dev Initializes the transaction broadcaster like this:
    ///
    /// - If $ETH_FROM is defined, use it.
    /// - Otherwise, derive the broadcaster address from $MNEMONIC.
    /// - If $MNEMONIC is not defined, default to a test mnemonic.
    ///
    /// The use case for $ETH_FROM is to specify the broadcaster key and its address via the command line.
    constructor() {
        address from = vm.envOr({ name: "ETH_FROM", defaultValue: address(0) });
        if (from != address(0)) {
            broadcaster = from;
        } else {
            mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
            (broadcaster,) = deriveRememberKey({ mnemonic: mnemonic, index: 0 });
        }

        networks[Chains.ArbitrumSepolia] = Network("arbitrum_sepolia", 421_614, 40_231);
        networks[Chains.OptimismSepolia] = Network("optimism_sepolia", 11_155_420, 40_232);
        networks[Chains.PolygonAmoy] = Network("mumbai", 80_002, 40_109);
        networks[Chains.BaseSepolia] = Network("base_sepolia", 84_532, 40_245);
    }

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }

    function _createSelectFork(Chains chain) internal {
        vm.createSelectFork(vm.rpcUrl(networks[chain].name));
    }

    function _createFork(Chains chain) internal {
        vm.createFork(vm.rpcUrl(networks[chain].name));
    }

    function _getNetwork(uint256 chainId) internal view returns (Network memory) {
        for (uint256 i = 0; i < deployedChains.length; i++) {
            if (networks[deployedChains[i]].chainId == chainId) {
                return networks[deployedChains[i]];
            }
        }
        revert("Network not found");
    }

    function _getAllNetworks() internal view returns (Network[] memory) {
        Network[] memory allNetworks = new Network[](deployedChains.length);
        for (uint256 i = 0; i < deployedChains.length; i++) {
            allNetworks[i] = networks[deployedChains[i]];
        }
        return allNetworks;
    }

    function _getChainKey(uint256 chainId) internal view returns (string memory) {
        return string.concat(".", _getNetwork(chainId).name);
    }
}
