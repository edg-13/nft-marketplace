// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/IPrimaryMarket.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITicketNFT.sol";
import "./TicketNFT.sol";
import "./PurchaseToken.sol";

contract PrimaryMarket is IPrimaryMarket{

    TicketNFT public immutable ticket;
    IERC20 public immutable token;
    address payable public immutable marketAdmin;
    uint256 public ticketPrice;

    constructor(IERC20 purchaseToken){
        ticket = new TicketNFT(address(this));
        marketAdmin = payable(msg.sender);
        token = purchaseToken;
        ticketPrice = 100e18;
    }

    function admin() public view returns (address) {
        return marketAdmin;
    }

    function purchase(string memory holderName) external {
        address purchaser = msg.sender;
        token.transferFrom(purchaser, marketAdmin, ticketPrice);
        ticket.mint(purchaser, holderName);
        emit Purchase(purchaser, holderName);
    }

    function getTicket() external view returns (address){
        return address(ticket);
    }
}
