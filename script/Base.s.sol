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

    enum Chains {
        ArbitrumSepolia,
        OptimismSepolia,
        PolygonAmoy,
        BaseSepolia,
        MantleSepolia,
        ScrollSepolia,
        AstarZkyoto,
        AvalancheFuji,
        BNBTestnet,
        BlastSepolia,
        ZkSyncSepolia,
        PolygonCardona
    }

    string[] internal deployChainNames = [
        "arbitrum_sepolia",
        "optimism_sepolia",
        "amoy",
        "base_sepolia",
        "mantle_sepolia",
        "scroll_sepolia",
        "astar_zkyoto",
        "avalanche_fuji",
        "bnb_testnet",
        "blast_sepolia",
        "zksync_sepolia",
        "polygon_cardona"
    ];

    Chains[] internal deployedChains = [
        Chains.ArbitrumSepolia,
        Chains.OptimismSepolia,
        Chains.PolygonAmoy,
        Chains.BaseSepolia,
        Chains.MantleSepolia,
        Chains.ScrollSepolia,
        Chains.AstarZkyoto,
        Chains.AvalancheFuji,
        Chains.BNBTestnet,
        Chains.BlastSepolia,
        Chains.ZkSyncSepolia,
        Chains.PolygonCardona
    ];

    Chains[] internal lzChains = [
        Chains.OptimismSepolia,
        Chains.BaseSepolia,
        Chains.ScrollSepolia,
        Chains.AstarZkyoto,
        Chains.PolygonCardona,
        Chains.AvalancheFuji,
        Chains.BNBTestnet,
        Chains.BlastSepolia
    ];

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
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        broadcaster = vm.addr(privateKey);

        // get networks
        for (uint256 i = 0; i < deployedChains.length; i++) {
            Chains chain = deployedChains[i];
            string memory chainName = deployChainNames[i];
            string memory chainKey = string.concat(".", chainName);
            uint256 chainId = vm.parseJsonUint(deploymentsJson, string.concat(chainKey, ".chainId"));
            uint32 eid = uint32(vm.parseJsonUint(deploymentsJson, string.concat(chainKey, ".eid")));

            networks[chain] = Network(chainName, chainId, eid);
        }
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

    function _getChainId(string memory chainName) internal view returns (uint256) {
        for (uint256 i = 0; i < deployedChains.length; i++) {
            if (keccak256(abi.encodePacked(networks[deployedChains[i]].name)) == keccak256(abi.encodePacked(chainName)))
            {
                return networks[deployedChains[i]].chainId;
            }
        }
        revert("Chain not found");
    }
}
