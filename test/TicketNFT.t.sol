// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/SecondaryMarket.sol";

contract BasicTest is Test {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed ticketID
    );
    event Approval(
        address indexed holder,
        address indexed approved,
        uint256 indexed ticketID
    );

    event Purchase(address indexed holder, string indexed holderName);

    PurchaseToken public paymentToken;
    TicketNFT public ticket;
    PrimaryMarket public priMark;
    SecondaryMarket public secMark;
    uint256 price = 100e18;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    address public david = makeAddr("david");

    function setUp() public {
        paymentToken = new PurchaseToken();
        //alice is admin
        vm.prank(alice);
        priMark = new PrimaryMarket(paymentToken);
        ticket = TicketNFT(priMark.getTicket());
        secMark = new SecondaryMarket(paymentToken, priMark);
    }

    function buyTicket(address buyer, string memory name) public {
        vm.deal(buyer, 1 ether);
        vm.startPrank(buyer);
        paymentToken.mint{value: 1e18}();
        paymentToken.approve(address(priMark), 100e18);
        priMark.purchase(name);
        vm.stopPrank();
    }
}

contract TicketTest is BasicTest{

    function testUnmintedTicket() public {
        vm.expectRevert("Ticket does not exist");
        ticket.holderOf(500);
    }

    function testApprovedTransfer() public {
        buyTicket(bob, "billybob");
        vm.prank(bob);
        vm.expectEmit(true, true, true, false);
        emit Approval(bob, charlie, 0);
        ticket.approve(charlie, 0);
        vm.prank(charlie);
        vm.expectEmit(true, true, true, false);
        emit Transfer(bob, david, 0);
        ticket.transferFrom(bob, david, 0);
        assertEq(ticket.holderOf(0), david);
        assertEq(ticket.balanceOf(david), 1);
        assertEq(ticket.balanceOf(bob), 0);
        assertEq(ticket.getApproved(0), address(0));
    }

    function testUnapprovedTransfer() public {
        buyTicket(bob, "billybob");
        vm.prank(charlie);
        vm.expectRevert("not authorized");
        ticket.transferFrom(bob, david, 0);
    }

    function testUnmintedTransfer() public {
        buyTicket(bob, "billybob");
        vm.prank(bob);
        vm.expectRevert("not authorized");
        ticket.transferFrom(bob, charlie, 1);
    }

    function testUpdatedName() public {
        buyTicket(bob, "billybob");
        vm.prank(bob);
        ticket.updateHolderName(0, "brandon");
        assertEq(ticket.holderNameOf(0), "brandon");
    }

    function testExpiredTicket() public {
        uint256 currentTime = block.timestamp;
        buyTicket(bob, "billybob");
        uint256 addition = currentTime + (10*86400) + 1;
        vm.warp(addition);
        vm.prank(alice);
        vm.expectRevert("Ticket has already been used / is expired");
        ticket.setUsed(0); 
    }

    function testInvalidUsedSetter() public {
        buyTicket(bob, "billybob");
        vm.prank(charlie);
        vm.expectRevert("No admin privileges");
        ticket.setUsed(0);
    }

    function testSetUsed() public {
        buyTicket(bob, "billybob");
        vm.prank(alice);
        ticket.setUsed(0);
        assertEq(ticket.isExpiredOrUsed(0), true);
    }

    function testAlreadyUsed() public {
        buyTicket(bob, "billybob");
        uint256 currentTime = block.timestamp;
        vm.warp(currentTime + (86400*11));
        vm.prank(alice);
        vm.expectRevert("Ticket has already been used / is expired");
        ticket.setUsed(0);
    }
}