// 1. deploy mocks when we are on local anvil chain
// 2. keep track of contract addresses across different chains

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // if we are on local anvil, we deploy mocks
    // Otherwise, grab the exisitng addresses from the live network

    uint8 public constant decimals = 8;
    int256 public constant initialPrice = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD pricefeed address
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethConfig = NetworkConfig(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        return ethConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // 1. deploy mock
        // 2. return mock address

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(decimals, initialPrice);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig(address(mockPriceFeed));
        return anvilConfig;
    }
}
