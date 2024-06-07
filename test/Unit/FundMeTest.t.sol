// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {MockV3Aggregator} from "../../test/Mocks/MockV3Aggregator.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    /*When you deploy a contract from within another contract, 
    msg.sender inside the constructor of the new contract (FundMe in this case) 
    is the address of the contract that is deploying it (FundMeTest)*/

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        //console.log(fundMe.i_owner());
        //console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender, "sender is not the owner");
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); //next line should be false for test to pass
        fundMe.fund(); //0 value passed
    }

    modifier funded() {
        vm.prank(USER);
        vm.deal(USER, STARTING_BALANCE);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        //vm.prank(USER); // the next tx will be sent by user
        vm.deal(USER, STARTING_BALANCE); // to add funds to prank user
        //fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunder() public funded {
        //vm.prank(USER); // the next tx will be sent by user
        vm.deal(USER, STARTING_BALANCE); // to add funds to prank user
        //fundMe.fund{value: SEND_VALUE}();
        assertEq(fundMe.getFunder(0), USER, "funder was not added corrrectly");
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.deal(USER, STARTING_BALANCE); // to add funds to prank user
        //vm.deal(owner, STARTING_BALANCE); // to add funds to owner

        // Fund contract from user address
        //vm.prank(USER);
        //fundMe.fund{value: SEND_VALUE}();

        vm.prank(USER);
        vm.expectRevert();
        fundMe.cheaperWithdraw();

        //Check that contract balance is zero
        assertEq(address(fundMe).balance, SEND_VALUE, "contract balance is not zero after withdrawl");

        //Check that funded amount is reset to zero
        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE, "funded amount is not reset to zero");

        //Check that funder array is cleared
        assertEq(fundMe.getFunderLength(), 1, "funder array is not empty after withdrawl");
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0, "fundMe balance is not zero after withdrawl");
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() public funded {
        //uint256 initialBalance = address(this).balance;

        //simulate 10 funders
        for (uint256 i = 0; i < 10; i++) {
            //address funder = address(uint160(i + 1));
            //vm.deal(funder, 1 ether); // give each funder 1 ether
            //vm.prank(funder); // make each funder as the next tx sender
            hoax(address(uint160(i + 1)), 1 ether); //hoax = vm.deal + vm.prank
            fundMe.fund{value: 1 ether}();
            assertEq(fundMe.getAddressToAmountFunded(address(uint160(i + 1))), 1 ether);
        }

        uint256 contractBalance = address(fundMe).balance;
        assertEq(contractBalance, 10.1 ether);

        // withdraw funds as owner
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //check that contract balance is zero after withdrawl
        assertEq(address(fundMe).balance, 0);
        //assertEq(address(this).balance, initialBalance + 10 ether);

        //check that all funder balances in the contract are set to zero
        for (uint256 i = 0; i < 10; i++) {
            address funder = address(uint160(i + 1));
            assertEq(fundMe.getAddressToAmountFunded(funder), 0);
        }
    }

    function cheaperTestWithdrawWithMultipleFunders() public funded {
        //uint256 initialBalance = address(this).balance;

        //simulate 10 funders
        for (uint256 i = 0; i < 10; i++) {
            //address funder = address(uint160(i + 1));
            //vm.deal(funder, 1 ether); // give each funder 1 ether
            //vm.prank(funder); // make each funder as the next tx sender
            hoax(address(uint160(i + 1)), 1 ether); //hoax = vm.deal + vm.prank
            fundMe.fund{value: 1 ether}();
            assertEq(fundMe.getAddressToAmountFunded(address(uint160(i + 1))), 1 ether);
        }

        uint256 contractBalance = address(fundMe).balance;
        assertEq(contractBalance, 10.1 ether);

        // withdraw funds as owner
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        //check that contract balance is zero after withdrawl
        assertEq(address(fundMe).balance, 0);
        //assertEq(address(this).balance, initialBalance + 10 ether);

        //check that all funder balances in the contract are set to zero
        for (uint256 i = 0; i < 10; i++) {
            address funder = address(uint160(i + 1));
            assertEq(fundMe.getAddressToAmountFunded(funder), 0);
        }
    }
}
