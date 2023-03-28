// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/ISecondaryMarket.sol";
import "../interfaces/IPrimaryMarket.sol";
import "../interfaces/ITicketNFT.sol";
import "../interfaces/IERC20.sol";
import "./TicketNFT.sol";
import "./PrimaryMarket.sol";
import "./PurchaseToken.sol";


contract SecondaryMarket is ISecondaryMarket{

    PrimaryMarket public immutable primaryMarket;
    TicketNFT public immutable ticket;
    IERC20 public token;

    mapping(uint256 => address) public listedOwners;
    mapping(uint256 => uint256) public listedPrices;
    mapping(uint256 => bool) public isListed;

    constructor(IERC20 purchaseToken, PrimaryMarket priMark) {
        token = purchaseToken;
        primaryMarket = priMark;
        ticket = TicketNFT(primaryMarket.getTicket());
    }

    function listTicket(uint256 ticketID, uint256 price) external {
        address lister = msg.sender;
        require(ticket.holderOf(ticketID)==lister, "not authorized to sell this ticket");
        require(ticket.isExpiredOrUsed(ticketID)==false, "invalid ticket cannot be listed");
        require(isListed[ticketID]==false, "Ticket already listed");

        listedOwners[ticketID] = lister;
        listedPrices[ticketID] = price;
        isListed[ticketID] = true;
        ticket.transferFrom(lister, address(this), ticketID);
        emit Listing(ticketID, lister, price);
    }

    function purchase(uint256 ticketID, string calldata name) external {
        address buyer = msg.sender;
        address payable seller = payable(listedOwners[ticketID]);
        uint256 price = listedPrices[ticketID];
        uint256 fee = price/20;
        require(isListed[ticketID], "Ticket unavailable");
        require(!ticket.isExpiredOrUsed(ticketID), "ticket is no longer valid");
        if (buyer==primaryMarket.admin()){
            token.transferFrom(buyer, seller, price);
        }
        else{
            token.transferFrom(buyer, seller, price-fee);
            token.transferFrom(buyer, primaryMarket.admin(), fee);
        }
        ticket.updateHolderName(ticketID, name);
        ticket.transferFrom(address(this), buyer, ticketID);
        emit Purchase(buyer, ticketID, price, name);

        delete listedOwners[ticketID];
        delete listedPrices[ticketID];
        isListed[ticketID] = false;
    }

    function delistTicket(uint256 ticketID) external {
        require(isListed[ticketID], "ticket has not been listed");
        address holder = listedOwners[ticketID];
        require(holder==msg.sender, "not authorized to delist this ticket");
        isListed[ticketID] = false;
        ticket.transferFrom(address(this), holder, ticketID);
        delete listedPrices[ticketID];
        delete listedOwners[ticketID];
        emit Delisting(ticketID);
    }
}