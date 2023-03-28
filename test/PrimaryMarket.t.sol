// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/PrimaryMarket.sol";
import "./TicketNFT.t.sol";

contract PrimaryTest is BasicTest {

    function testAdmin() public {
        assertEq(priMark.admin(), alice);
    }

    function testFailPurchase() public {
        vm.startPrank(charlie);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        priMark.purchase("charlie");
        assertEq(ticket.balanceOf(charlie), 0);
    }

    function testPurchaseNotPrimaryMarket() public {
        vm.startPrank(charlie);
        vm.expectRevert("Caller not from primary market"); 
        ticket.mint(charlie, "charlie");
    }

    function testSuccessPurchase() public {
        vm.deal(bob, 10 ether);
        vm.startPrank(bob);
        paymentToken.mint{value: 5e18}();
        assertEq(paymentToken.balanceOf(bob), 5e20);
        paymentToken.approve(address(priMark), 100e18);
        vm.expectEmit(true, true, false, false);
        emit Purchase(bob, "billybob");
        priMark.purchase("billybob");

        assertEq(paymentToken.balanceOf(bob), 4e20);
        assertEq(paymentToken.balanceOf(alice), 1e20);
        assertEq(ticket.holderOf(0), bob);
        assertEq(ticket.balanceOf(bob), 1);
    }

    function testSoldOut() public {
        for (uint i=0; i<1000; i++) {
            buyTicket(bob, "billybob");
        }
        assertEq(ticket.holderOf(999), bob);
        assertEq(ticket.balanceOf(bob), 1000);

        vm.deal(charlie, 1 ether);
        vm.startPrank(charlie);
        paymentToken.mint{value: 1e18}();
        paymentToken.approve(address(priMark), 100e18);
        vm.expectRevert("Tickets sold out");
        priMark.purchase("charles");
    }
}