# Smart Auction Contract

This repository contains a decentralized auction smart contract built in Solidity, deployed on the Scroll Sepolia testnet. The contract facilitates time-limited bidding rounds with automatic deadline extensions, secure refunds for non-winning participants, and transparent winner selection.

## Overview

The contract implements the following core features:

- Accepts bids only if they exceed the current top bid by a minimum percentage.
- Automatically extends the auction deadline if a bid is placed near the end.
- Allows non-winning bidders to reclaim their funds either partially (before auction end) or after the auction concludes.
- Deducts a small fee from refunds to simulate operational costs or treasury contributions.

---

## Functions

| Name              | Description                                                                 |
|-------------------|-----------------------------------------------------------------------------|
| `bid()`           | Places a new bid. Must exceed the current highest bid by at least 5%. Automatically extends the auction if close to the deadline. |
| `showWinner()`    | Returns the current highest bidder's address and bid amount.                |
| `showOffers()`    | Displays all bids submitted during the auction.                             |
| `refund()`        | Can be called once by the contract owner after the auction ends. Refunds all bidders except the winner, applying a 2% deduction. |
| `partialRefund()` | Allows bidders to reclaim their previous (outbid) amounts before the auction ends. |

---

## State Variables

### General

- `owner`: Address of the contract deployer.
- `startTime`: Timestamp when the auction started.
- `stopTime`: Timestamp when the auction is scheduled to end.
- `auctionEnded`: Boolean flag indicating whether the auction has been finalized.

### Constants

- `AUCTION_DURATION`: Fixed auction duration (7 days).
- `EXTENSION_TIME`: Additional time added to the deadline when late bids are placed (10 minutes).
- `MIN_BID_INCREMENT_PERCENT`: Minimum percentage required to exceed the current top bid (5%).
- `REFUND_FEE_PERCENT`: Fixed fee deducted from refunds (2%).

### Bidding Logic

- `bids`: An array of all `Bidder` structs, which include bid amount and bidder address.
- `winner`: Struct holding the address and amount of the leading bid.

### User Tracking

- `userBids`: Mapping that stores an array of bid amounts for each user.
- `refundableAmount`: Tracks how much a user can reclaim.
- `hasWithdrawn`: Ensures each user can withdraw only once.

---

## Events

| Event                         | Description                                                         |
|-------------------------------|---------------------------------------------------------------------|
| `NewOffer(address, uint256)`  | Emitted every time a valid bid is placed.                          |
| `AuctionEnded(address, uint256)` | Emitted when the auction concludes and the winner is confirmed.  |
| `PartialRefund(address, uint256)` | Emitted when a user retrieves a partial refund before the end.  |

---

## Usage Instructions (Remix + Metamask)

1. **Deploy the Contract**  
   Deploy using the Remix IDE, selecting the Scroll Sepolia testnet via Metamask.

2. **Interact with the Contract**  
   - Use the `bid()` function by entering a value (e.g., `1 ether`) and submitting the transaction.
   - Track the current leader with `showWinner()`.
   - View all bids using `showOffers()`.

3. **Finalizing the Auction**  
   - Once the auction has ended (7 days after deployment), the owner can call `refund()` to process non-winner refunds.

4. **Early Withdrawals**  
   - Users may call `partialRefund()` before the auction ends to reclaim any overbid amounts.

---

## Security Considerations

- Bids are validated to be at least 5% higher than the current leading offer to avoid spam and ensure fair competition.
- The auction can be finalized only once and only by the contract owner.
- Refunds are processed with a flat 2% deduction.
- Each user’s withdrawal is restricted to a one-time action to prevent double claims.

---

## Testing Environment

- **Network**: Scroll Sepolia (L2 Testnet)
- **Solidity Version**: ^0.8.20
- **Tooling**: Remix IDE, Metamask, Etherscan for contract verification

---

## License

This project is licensed under the MIT License.
