// SPDX-License-Identifier: MIT

pragma solidity 0.8;

import {Script} from "lib/forge-std/src/Script.sol";
import {FundMe} from "src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function deployFundMe() public returns (FundMe, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        address priceFeed = helperConfig.getConfigByChainId(block.chainid).priceFeed;
        vm.startBroadcast();
        FundMe fundme = new FundMe(priceFeed);
        vm.stopBroadcast();
        return (fundme, helperConfig);
    }

    function run() external returns (FundMe, HelperConfig) {
       return deployFundMe();
    }
}
