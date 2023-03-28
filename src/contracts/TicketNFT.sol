// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";
import "../interfaces/IPrimaryMarket.sol";
import "../../lib/StringUtils.sol";
import "./PrimaryMarket.sol";

contract TicketNFT is ITicketNFT {
    uint256 internal numSold;

    mapping(uint256 => address) internal ticketHolders;
    mapping(uint256 => string) internal holderNames;
    mapping(uint256 => uint256) internal expiryTime;
    mapping(uint256 => bool) internal used;

    mapping(address => uint256) internal balances;
    mapping(uint => address) ticketApprovals;

    address primaryMarketAddr;
    PrimaryMarket priMark;

    constructor(address primaryMarket){
        numSold = 0;
        primaryMarketAddr = primaryMarket;
        priMark = PrimaryMarket(primaryMarketAddr);
    }

    function mint(address holder, string memory holderName) external {
        require(numSold<1000, "Tickets sold out");
        require(msg.sender==primaryMarketAddr, "Caller not from primary market");

        uint256 expTime = block.timestamp + (10*86400);
        ticketHolders[numSold] = holder;
        holderNames[numSold] = holderName;
        expiryTime[numSold] = expTime;
        used[numSold] = false;
        balances[holder]+=1;
        emit Transfer(address(0), holder, numSold);
        numSold+=1;

    }

    function balanceOf(address holder) external view returns (uint256 balance) {
        return balances[holder];
    }

    function holderOf(uint256 ticketID) external view returns (address holder) {
        require(ticketExists(ticketID), "Ticket does not exist");
        return ticketHolders[ticketID];
    }

    function transferFrom(
        address from,
        address to,
        uint256 ticketID
    ) external {
        require(from!=address(0), "Cannot be zero address");
        require(to!=address(0), "Cannot be zero address");
        require(isApprovedOrOwner(ticketID, msg.sender), "not authorized");
        ticketHolders[ticketID] = to;
        balances[from] -= 1;
        balances[to] += 1;
        emit Transfer(from, to, ticketID);
        ticketApprovals[ticketID] = address(0);
        emit Approval(to, address(0), ticketID);
        //No need to update holder name as mentioned on Edstem
        
    }

    function approve(address to, uint256 ticketID) public {
        address owner = ticketHolders[ticketID];
        require(owner==msg.sender, "not authorized");
        require(ticketExists(ticketID), "Ticket does not exist");
        //REMEMBER TO TEST APPROVAL CLEARANCE AFTER TRANSFER
        ticketApprovals[ticketID] = to;
        emit Approval(owner, to, ticketID);
    }

    function getApproved(uint256 ticketID) external view returns (address operator) {
        require(ticketExists(ticketID), "Ticket does not exist");
        return ticketApprovals[ticketID];
    }

    function holderNameOf(uint256 ticketID) external view returns (string memory holderName){
        require(ticketExists(ticketID), "Ticket does not exist");
        return holderNames[ticketID];
    }

    function updateHolderName(uint256 ticketID, string calldata newName) external {
        require(ticketExists(ticketID), "Ticket does not exist");
        address owner = ticketHolders[ticketID];
        require(owner==msg.sender, "not authorized");
        holderNames[ticketID] = newName;
    }

    function setUsed(uint256 ticketID) external {
        require(msg.sender==priMark.admin(), "No admin privileges");
        require(ticketExists(ticketID), "Ticket does not exist");
        require(isExpiredOrUsed(ticketID)==false, "Ticket has already been used / is expired");
        used[ticketID] = true;
    }

    function ticketExists(uint256 ticketID) public view returns (bool) {
        return (ticketID<=numSold);
    }

    function isExpiredOrUsed(uint256 ticketID) public view returns (bool) {
        //CHANGE EXTERNAL TO PUBLIC
        require(ticketExists(ticketID), "Ticket does not exist");
        bool isUsed = used[ticketID];
        bool isExp = (block.timestamp>expiryTime[ticketID]);
        return isUsed || isExp;

    }

    function isApprovedOrOwner(uint256 ticketID, address account) public view returns (bool){
        bool isApproved = (account==ticketApprovals[ticketID]);
        bool isOwner = (account==ticketHolders[ticketID]);
        return isApproved || isOwner;
    }

}