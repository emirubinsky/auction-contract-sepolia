// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Auction Contract
 * @notice Implements a time-based auction with dynamic deadline extension, deposit tracking,
 * full and partial refunds, and 5% minimum increment logic.
 */
contract Auction {

    struct Bidder {
        uint256 amount;
        address bidder;
    }

    address public owner;
    uint256 public startTime;
    uint256 public stopTime;
    uint256 public constant AUCTION_DURATION = 7 days;
    uint256 public constant EXTENSION_TIME = 10 minutes;
    uint256 public constant MIN_BID_INCREMENT_PERCENT = 5;
    uint256 public constant REFUND_FEE_PERCENT = 2;

    Bidder public winner;
    Bidder[] public bids;

    mapping(address => uint256[]) public userBids;
    mapping(address => uint256) public refundableAmount;
    mapping(address => bool) public hasWithdrawn;

    bool public auctionEnded;

    event NewOffer(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event PartialRefund(address indexed bidder, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier isActive() {
        require(block.timestamp < stopTime, "Auction is no longer active");
        require(!auctionEnded, "Auction has ended");
        _;
    }

    modifier hasEnded() {
        require(block.timestamp >= stopTime || auctionEnded, "Auction is still active");
        _;
    }

    constructor() {
        owner = msg.sender;
        startTime = block.timestamp;
        stopTime = startTime + AUCTION_DURATION;
        winner = Bidder(0, address(0));
    }

    /**
     * @notice Places a bid that must be at least 5% higher than the current winning bid.
     * @dev Extends the auction time if bid placed in last 10 minutes.
     */
    function bid() external payable isActive {
        require(msg.value > winner.amount * (100 + MIN_BID_INCREMENT_PERCENT) / 100,
            "Bid must be at least 5% higher than current winning bid");

        // Record user bid
        userBids[msg.sender].push(msg.value);
        refundableAmount[msg.sender] += msg.value;

        // Save bid
        bids.push(Bidder(msg.value, msg.sender));

        // Update winner
        winner.amount = msg.value;
        winner.bidder = msg.sender;

        // If bid is in the last 10 minutes, extend auction
        if (stopTime - block.timestamp <= EXTENSION_TIME) {
            stopTime += EXTENSION_TIME;
        }

        emit NewOffer(msg.sender, msg.value);
    }

    /**
     * @notice Returns the current winning bid and bidder.
     */
    function showWinner() external view returns (Bidder memory) {
        return winner;
    }

    /**
     * @notice Returns all bids with amounts and bidder addresses.
     */
    function showOffers() external view returns (Bidder[] memory) {
        return bids;
    }

    /**
     * @notice Ends the auction and allows non-winners to claim refund (minus 2% fee).
     * @dev Can only be called by the contract owner.
     */
    function refund() external onlyOwner hasEnded {
        require(!auctionEnded, "Already finalized");
        auctionEnded = true;

        for (uint256 i = 0; i < bids.length; i++) {
            address bidderAddr = bids[i].bidder;
            uint256 totalBid = refundableAmount[bidderAddr];

            if (bidderAddr != winner.bidder && totalBid > 0 && !hasWithdrawn[bidderAddr]) {
                uint256 refundAmount = totalBid * (100 - REFUND_FEE_PERCENT) / 100;
                hasWithdrawn[bidderAddr] = true;
                refundableAmount[bidderAddr] = 0;
                payable(bidderAddr).transfer(refundAmount);
            }
        }

        emit AuctionEnded(winner.bidder, winner.amount);
    }

    /**
     * @notice Allows users to withdraw the amount from previous (outbid) offers during the auction.
     */
    function partialRefund() external isActive {
        require(userBids[msg.sender].length > 1, "No previous bids to refund");

        uint256 refundSum = 0;

        for (uint256 i = 0; i < userBids[msg.sender].length - 1; i++) {
            refundSum += userBids[msg.sender][i];
            userBids[msg.sender][i] = 0;
        }

        require(refundSum > 0, "Nothing to refund");

        refundableAmount[msg.sender] -= refundSum;
        payable(msg.sender).transfer(refundSum);

        emit PartialRefund(msg.sender, refundSum);
    }
}
