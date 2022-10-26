//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error FundMe__NotOwner();

/// @title Acontract for crown fundting
/// @author Vsevolod Kulev
/// @notice This contract is to demo a sample funding contract
/// @dev This implements price feeds as our libary
contract FundMe {
    using PriceConverter for uint256;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner; //immutable set only once, butr not at the declaration moment
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    AggregatorV3Interface private s_priceFeed;

    //modifier can be added to function declaration to add executable code before function
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        } //revert() does same thing as required but
        _; //_ represents all the rest code
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //receive() if money is sent, but no specific function called
    // receive() external payable {
    //     fund();
    // }

    //fallback() if money is sent, but no called function exists fallback is called
    // fallback() external payable {
    //     fund();
    // }

    /// @notice This function funds this contract
    /// @dev This implements price feeds as our libary
    function fund() public payable {
        //Want to be able to set a minimum amount of fund amount in USD
        //How to get ETH to this contract
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Not enough ETH sent"
        ); //1e18 == 1* 10^18
        //18 decimals
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        //Removed funds from s_addressToAmountFunded mapping
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //Clear s_funders array
        s_funders = new address[](0);
        //Withdraw the funds
        //call
        (
            bool callSuccess, /*bytes memory dataReturned*/

        ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        //mappings cant be i memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    //Chainlink external operations in decentralized context
    //Chainlink data feeds - for getting data from the real world
    //Chainlink VRF - random number from the real world
    //Chainlink keepers - event driven computations. E.g. if something happens do something
    //Chainlink to any API - ultimate customization of chainlink. E.g using APIs
}
