// SPDX-License-Identifier: MIT
pragma solidity 0.8;

import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";
import {Script, console2} from "forge-std/Script.sol";

abstract contract CodeConstant {
    uint8 public constant DECIMAL = 8;
    int256 public constant INTIAL_PRICE = 2000e8;

    /*//////////////////////////////////////////////////////////////
                               CHAIN IDS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstant, Script {
    /*////////////////////////////////////////
                Errors
    ///////////////////////////////////////*/
    
    error HelperConfig_InvalidChainId();

    /*////////////////////////////////////////
                Types
    ///////////////////////////////////////*/

    struct NetworkConfig {
        address priceFeed;
    }

    /*////////////////////////////////////////
                State Variables
    ///////////////////////////////////////*/
    // Local network state variables
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZKSyncSepoliaConfig();
    }
    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory) {
        if(networkConfigs[chainId].priceFeed != address(0)) {
            return networkConfigs[chainId];
        } else if(chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig_InvalidChainId();
        }
    }

    /*//////////////////////////////////////////////////////////////
                                CONFIGS
    //////////////////////////////////////////////////////////////*/

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig ({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
    }

    function getZKSyncSepoliaConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig ({
            priceFeed: 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF
        });
    }

    /*///////////////////////////////////////// 
                Local Config
    ///////////////////////////////////////////*/

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Check to see if we set an active network config
        if(localNetworkConfig.priceFeed != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMAL, INTIAL_PRICE);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return localNetworkConfig;
    }
}
