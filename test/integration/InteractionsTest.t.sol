// SPDX-License-Identifier: MIT

pragma solidity 0.8;

import {Test} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe} from "../../script/Interactions.s.sol";
import {console} from "forge-std/Script.sol";

contract InteractionsTest is Test {
    FundMe fundme;
    HelperConfig helperConfig;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 100 ether;
    uint8 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundme = new DeployFundMe();
        (fundme, helperConfig) = deployFundme.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        console.log("USER Balance %s", address(USER).balance);
        console.log("SEND ETHER Amount %s", SEND_VALUE);
        _;
    }

    function testUserCanFundInteractions() public  funded {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundme));
        address funder = fundme.getFunder(0);
        assertEq(funder, USER);
    }
}
