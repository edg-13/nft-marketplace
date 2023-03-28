// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/PrimaryMarket.sol";
import "./TicketNFT.t.sol";

contract SecondaryTest is BasicTest {
    event Listing(
        uint256 indexed ticketID,
        address indexed holder,
        uint256 price
    );
    event Purchase(
        address indexed purchaser,
        uint256 indexed ticketID,
        uint256 price,
        string newName
    );
    event Delisting(uint256 indexed ticketID);

    function quickList(address lister, uint256 price) public{
        buyTicket(lister, "lister");
        vm.startPrank(bob);
        ticket.approve(address(secMark), 0);
        secMark.listTicket(0, price);
        vm.stopPrank();
    }

    function testSuccessListing() public {
        buyTicket(bob, "billybob");
        assertEq(ticket.holderOf(0), bob);
        vm.startPrank(bob);
        ticket.approve(address(secMark), 0);
        vm.expectEmit(true, true, false, true);
        emit Listing(0, bob, 50e18);
        secMark.listTicket(0, 50e18);
        assertEq(secMark.listedOwners(0), bob);
        assertEq(secMark.listedPrices(0), 50e18);
        assertEq(secMark.isListed(0), true);
    }

    function testUnauthorizedList() public {
        buyTicket(bob, "billybob");
        vm.prank(bob);
        ticket.approve(charlie, 0);
        vm.prank(charlie);
        vm.expectRevert("not authorized to sell this ticket");
        secMark.listTicket(0, 50e18);
    }

    function testInvalidList() public {
        buyTicket(bob, "billybob");
        vm.prank(alice);
        ticket.setUsed(0);
        vm.prank(bob);
        vm.expectRevert("invalid ticket cannot be listed");
        secMark.listTicket(0, 50e18);
    }

    function testSuccessPurchase() public {
        quickList(bob, 120e18);
        vm.deal(david, 10 ether);
        vm.startPrank(david);
        paymentToken.mint{value: 10e18}();
        paymentToken.approve(address(secMark), 120e18);
        vm.expectEmit(true, true, true, true);
        emit Purchase(david, 0, 120e18, "david");
        secMark.purchase(0, "david");

        assertEq(ticket.holderOf(0), david);
        assertEq(ticket.holderNameOf(0), "david");
        assertEq(ticket.balanceOf(bob), 0);
        assertEq(ticket.getApproved(0), address(0));
        assertEq(secMark.isListed(0), false);
        assertEq(paymentToken.balanceOf(alice), 106e18);
        assertEq(paymentToken.balanceOf(bob), 114e18);
    }

    function testSuccessDelist() public {
        quickList(bob, 5e18);
        assertEq(secMark.isListed(0), true);
        vm.prank(bob);
        vm.expectEmit(true, false, false, false);
        emit Delisting(0);
        secMark.delistTicket(0);
        assertEq(secMark.isListed(0), false);
        assertEq(ticket.holderOf(0), bob);
    }

    function testUnauthorizedDelist() public {
        quickList(bob, 50e18);
        vm.prank(alice);
        vm.expectRevert("not authorized to delist this ticket");
        secMark.delistTicket(0);
        assertEq(secMark.isListed(0), true);
        assertEq(secMark.listedOwners(0), bob);
    }

    function testUnlistedDelist() public {
        quickList(bob, 50e18);
        vm.prank(alice);
        vm.expectRevert("ticket has not been listed");
        secMark.delistTicket(1);
        assertEq(ticket.balanceOf(alice), 0);
    }

    function testUnavailablePurchase() public {
        quickList(bob, 50e18);
        vm.prank(bob);
        secMark.delistTicket(0);
        vm.deal(charlie, 1 ether);
        vm.startPrank(charlie);
        paymentToken.mint{value: 1e18}();
        vm.expectRevert("Ticket unavailable");
        secMark.purchase(0, "charlie");
    }

    function testExpiredPurchase() public {
        quickList(bob, 5e18);
        uint256 time = block.timestamp + (86400*11);
        vm.warp(time);
        vm.deal(charlie, 1 ether);
        vm.startPrank(charlie);
        paymentToken.mint{value: 5e16}();
        paymentToken.approve(address(secMark), 5e18);
        vm.expectRevert("ticket is no longer valid");
        secMark.purchase(0, "charlie");
    }

    function testBuyAsAdmin() public {
        quickList(bob, 120e18);
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        paymentToken.mint{value: 1e18}();
        paymentToken.approve(address(secMark), 120e18);
        secMark.purchase(0, "alice");

        assertEq(paymentToken.balanceOf(bob), 120e18);
        assertEq(paymentToken.balanceOf(alice), 80e18);
    }
}