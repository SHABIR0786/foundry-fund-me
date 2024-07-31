// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract FundMe {
    using PriceConverter for uint256;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    uint256 public minimumUSDtowithdraw = 50 * 1e18;
    AggregatorV3Interface private s_priceFeed;
    address private i_owner;

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }
    
    function fund() public payable  {
       require((msg.value.getConversionRate(s_priceFeed)) >= minimumUSDtowithdraw, "Didn't send enough");
       s_funders.push(msg.sender);
       s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns(uint256) {
        return s_priceFeed.version();
    }

    function cheaperWithdraw() public onlyowner {
        uint256 funderLength = s_funders.length;
        for(uint256 index; index < funderLength; index++) {
            address funder = s_funders[index];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");

        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyowner {
        for(uint256 index; index < s_funders.length; index++) {
            address funder = s_funders[index];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");

        require(callSuccess, "Call failed");
    }

    modifier onlyowner {
        require(msg.sender == i_owner,"Sender is not owner");
        _;
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()
    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }


    /***
     * 
     * View / Pure functions (Getters)
     * 
     */
    function getAddressToAmountFunded(address fundingAddress) external view returns(uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns(address) {
        return s_funders[index];
    }

    function getOwner() external view returns(address) {
        return i_owner;
    }
}