// SPDX-License-Identifier: MIT
pragma solidity 0.8;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
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

    function testMinimumUsd() public view {
        assertEq(fundme.minimumUSDtowithdraw(), 50 * 1e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundme.getOwner(), msg.sender);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundme.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        _;
    }

    function testAddFunderToArrayofFunders() public funded {
        address funder = fundme.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanwithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundme.withdraw();
    }

    function testWithdrawWithASingleOwner() public funded {
        // Arrange 
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance; 

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundme.getOwner());
        fundme.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; 
        console.log(gasUsed);    

        // After Balance
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundmeBalance = address(fundme).balance;

        // Assert
        assertEq(endingFundmeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleOwners() public {
        // arrange 
        uint160 totalOwner = 10;
        uint160 startingOwner = 1;

        for(uint160 i = startingOwner; i < totalOwner; i++) {
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        // Arrange 
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance; 

        // Act 
        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();
        

        // After Balance
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;

        // Assert
        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }

        function testCheaperWithdrawFromMultipleOwners() public {
        // arrange 
        uint160 totalOwner = 10;
        uint160 startingOwner = 1;

        for(uint160 i = startingOwner; i < totalOwner; i++) {
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        // Arrange 
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance; 

        // Act 
        vm.startPrank(fundme.getOwner());
        fundme.cheaperWithdraw();
        vm.stopPrank();
        

        // After Balance
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;

        // Assert
        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }
}
