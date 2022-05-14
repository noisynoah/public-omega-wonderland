// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OMG is ERC20, ERC20Burnable, Ownable {
    struct Auction {
        bytes12 highestUser;
        uint256 highestBid;
        uint256 minBidRaise;
        uint startTime;
        uint closeTime;
    }

    uint256 private _auctionPool;
    mapping(bytes12 => Auction) private auctions;
    mapping(bytes12 => mapping(bytes12 => uint256)) private bids;
    mapping(bytes12 => mapping(bytes12 => address)) private refundAddress;

    constructor() ERC20("OMG Token", "OMG") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function blockTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    function auctionPool() public view returns (uint256) {
        return _auctionPool;
    }

    modifier onlyValidAuctionInput(bytes12 userId, bytes12 auctionId, uint256 value) {
        require(userId != "", "userId should not empty");
        require(auctionId != "", "userId should not empty");
        require(value > 0, "Value should greater than zero");
        _;
    }

    function initAuction(bytes12 userId, bytes12 auctionId, uint256 price) public onlyValidAuctionInput(userId, auctionId, price) returns (bool success) {
        require(auctions[auctionId].startTime == 0, "Already init auction");
        require(price > 0, "Bid should more than zero");

        // Transfer token
        _burn(msg.sender, price);
        _auctionPool += price;
        bids[auctionId][userId] += price;
        refundAddress[auctionId][userId] = msg.sender;

        // Add auction
        Auction memory auction = Auction({
        highestUser : userId,
        highestBid : price,
        minBidRaise : price / 10,
        startTime : block.timestamp,
        closeTime : block.timestamp + 86400 // Close after 1 day
        });

        auctions[auctionId] = auction;
        return true;
    }

    function isAttended(bytes12 userId, bytes12 auctionId) public view returns (bool attended) {
        return bids[auctionId][userId] > 0;
    }

    function isAuctionOpen(bytes12 auctionId) public view returns (bool open) {
        return auctions[auctionId].closeTime > block.timestamp;
    }

    function auctionCloseTime(bytes12 auctionId) public view returns (uint close) {
        return auctions[auctionId].closeTime;
    }

    function auctionRemain(bytes12 auctionId) public view returns (uint open) {
        return auctions[auctionId].closeTime > block.timestamp ? auctions[auctionId].closeTime - block.timestamp : 0;
    }

    function isWinAuction(bytes12 userId, bytes12 auctionId) public view returns (bool open) {
        Auction memory auction = auctions[auctionId];
        return auction.startTime > 0 && auction.closeTime <= block.timestamp && auction.highestUser == userId;
    }

    function userBid(bytes12 userId, bytes12 auctionId) public view returns (uint256 bid) {
        return bids[auctionId][userId];
    }

    function auctionMinBidRaise(bytes12 auctionId) public view returns (uint256 raise) {
        return auctions[auctionId].minBidRaise;
    }

    function highestBid(bytes12 auctionId) public view returns (uint256 bid) {
        return auctions[auctionId].highestBid;
    }

    function highestUser(bytes12 auctionId) public view returns (bytes12 user) {
        return auctions[auctionId].highestUser;
    }

    modifier onlyCanPlaceBid(bytes12 userId, bytes12 auctionId, uint256 bid) {
        require(isAuctionOpen(auctionId), "Auction should open");
        require(refundAddress[auctionId][userId] == address(0) || refundAddress[auctionId][userId] == msg.sender, string(abi.encodePacked("Should new user or use same address (", abi.encodePacked(refundAddress[auctionId][userId]), ")")));
        uint256 totalBid = bids[auctionId][userId] + bid;
        require(totalBid >= (auctions[auctionId].highestBid + auctions[auctionId].minBidRaise), "Bid should higher than the highest bid and raise at least 1/10 origin price");
        _;
    }

    function placeBid(bytes12 userId, bytes12 auctionId, uint256 bid) public onlyValidAuctionInput(userId, auctionId, bid) onlyCanPlaceBid(userId, auctionId, bid) returns (bool success) {
        uint256 totalBid = bids[auctionId][userId] + bid;

        // Transfer token
        _burn(msg.sender, bid);
        _auctionPool += bid;
        bids[auctionId][userId] = totalBid;

        if (refundAddress[auctionId][userId] == address(0)) {
            refundAddress[auctionId][userId] = msg.sender;
        }

        // get auction
        Auction storage auction = auctions[auctionId];

        // set highest bid
        auction.highestBid = totalBid;
        auction.highestUser = userId;

        uint extendTime = 3600 * 3;
        if (auction.closeTime < (block.timestamp + extendTime)) {
            // If less than 3 hour remain, extend the auction time
            auction.closeTime += extendTime;
        }

        return true;
    }

    modifier onlyAuctionClose(bytes12 auctionId) {
        require(auctions[auctionId].startTime > 0, "auction should exist");
        require(auctions[auctionId].closeTime <= block.timestamp, "auction should being close");
        _;
    }

    function refundAmount(bytes12 userId, bytes12 auctionId) public view returns (uint256 refund) {
        Auction memory auction = auctions[auctionId];
        if (auction.startTime > 0 && auction.closeTime <= block.timestamp && auction.highestUser != userId && bids[auctionId][userId] > 0) {
            return bids[auctionId][userId];
        }

        return 0;
    }

    function getRefund(bytes12 userId, bytes12 auctionId) public onlyAuctionClose(auctionId) returns (bool success) {
        uint256 refund = refundAmount(userId, auctionId);
        if (refund > 0 && refundAddress[auctionId][userId] == msg.sender) {
            // Transfer token
            _mint(msg.sender, refund);
            _auctionPool -= refund;
            bids[auctionId][userId] = 0;
        }

        return true;
    }
}
