// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Auction Contract
 * @notice Implements a decentralized auction system with the following features:
 * - Time-based auction with dynamic deadline extension
 * - Deposit and bid tracking
 * - Full and partial refunds with a 2% fee
 * - Minimum bid increment of 5%
 * - Emergency ETH recovery function
 * @dev All time-based logic uses block.timestamp
 * @custom:security Designed to be non-reentrant, single-auction contract
 */
contract Auction {
    struct Bidder {
        uint256 amount;
        address bidder;
    }

    // State variables
    address public owner;
    uint256 public startTime;
    uint256 public stopTime;
    uint256 public constant AUCTION_DURATION = 7 days;
    uint256 public constant EXTENSION_TIME = 10 minutes;
    uint256 public constant MIN_BID_INCREMENT_PERCENT = 5;
    uint256 public constant REFUND_FEE_PERCENT = 2;

    Bidder public winner;
    Bidder[] public bids;

    // Bidder tracking
    mapping(address => uint256[]) public userBids;
    mapping(address => uint256) public refundableAmount;
    mapping(address => bool) public hasWithdrawn;

    bool public auctionEnded;

    // Events for auction activity tracking
    event NewOffer(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event PartialRefund(address indexed bidder, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    /**
     * @notice Restricts function access to the contract owner only
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownr");
        _;
    }

    /**
     * @notice Ensures the auction is active and has not ended
     */
    modifier isActive() {
        require(block.timestamp < stopTime, "Inctv");
        require(!auctionEnded, "Ended");
        _;
    }

    /**
     * @notice Ensures the auction has ended either by time or manually
     */
    modifier hasEnded() {
        require(block.timestamp >= stopTime || auctionEnded, "Active");
        _;
    }

    /**
     * @notice Initializes the auction with the deployer as the owner
     * @dev Sets initial state and timing parameters
     */
    constructor() {
        owner = msg.sender;
        startTime = block.timestamp;
        stopTime = startTime + AUCTION_DURATION;
        winner = Bidder(0, address(0));
    }

    /**
     * @notice Places a new bid on the auction
     * @dev Automatically extends auction time if bid is placed near the end
     * Requirements:
     * - Auction must be active
     * - Bid must be at least 5% higher than the current highest bid
     * - The bid amount is sent via msg.value
     * Effects:
     * - Updates bid history and winner
     * - May extend auction time
     * - Emits NewOffer event
     */
    function bid() external payable isActive {
        require(msg.value > winner.amount * (100 + MIN_BID_INCREMENT_PERCENT) / 100, "Min incrmnt 5%");

        userBids[msg.sender].push(msg.value);
        refundableAmount[msg.sender] += msg.value;
        bids.push(Bidder(msg.value, msg.sender));

        winner.amount = msg.value;
        winner.bidder = msg.sender;

        if (stopTime - block.timestamp <= EXTENSION_TIME) {
            stopTime += EXTENSION_TIME;
        }

        emit NewOffer(msg.sender, msg.value);
    }

    /**
     * @notice Returns the current winning bidder info
     * @return Bidder struct with highest bid and bidder address
     */
    function showWinner() external view returns (Bidder memory) {
        return winner;
    }

    /**
     * @notice Returns the complete bid history
     * @return Array of Bidder structs with all bids
     */
    function showOffers() external view returns (Bidder[] memory) {
        return bids;
    }

    /**
     * @notice Processes refunds for all non-winning bidders
     * @dev Can only be called by the owner after the auction ends
     * Requirements:
     * - Only owner can call
     * - Auction must have ended
     * - Cannot be called more than once
     * Effects:
     * - Marks auction as finalized
     * - Processes refunds with a 2% fee
     * - Prevents double refunds via hasWithdrawn
     * - Emits AuctionEnded event
     */
    function refund() external onlyOwner hasEnded {
        require(!auctionEnded, "Finalized");
        auctionEnded = true;

        uint256 bidsLength = bids.length;
        uint256 i;

        for (i = 0; i < bidsLength; i++) {
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
     * @notice Allows bidders to withdraw previous (outbid) offers during the auction
     * @dev Only refunds previous bids, keeps the latest active bid
     * Requirements:
     * - Auction must be active
     * - Caller must have at least 2 bids
     * - Refundable amount must be non-zero
     * Effects:
     * - Refunds all but the last bid
     * - Updates refundable amount
     * - Emits PartialRefund event
     */
    function partialRefund() external isActive {
        require(userBids[msg.sender].length > 1, "No prev bids");

        uint256 refundSum = 0;
        uint256 i;

        for (i = 0; i < userBids[msg.sender].length - 1; i++) {
            refundSum += userBids[msg.sender][i];
            userBids[msg.sender][i] = 0;
        }

        require(refundSum > 0, "No refund");
        refundableAmount[msg.sender] -= refundSum;
        payable(msg.sender).transfer(refundSum);

        emit PartialRefund(msg.sender, refundSum);
    }

    /**
     * @notice Emergency function to recover ETH from the contract
     * @dev Only the owner can call
     * Requirements:
     * - Only owner can call
     * - Contract must have a positive balance
     * Effects:
     * - Transfers entire contract balance to owner
     * - Emits EmergencyWithdrawal event
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No bal");
        payable(owner).transfer(balance);
        emit EmergencyWithdrawal(owner, balance);
    }
}
