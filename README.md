# 🧾 Solidity Auction Contract (Scroll Sepolia)

This repository contains a smart contract written in Solidity for an on-chain auction system.  
It includes dynamic deadline extensions, deposit tracking, partial and final refunds, and a 5% minimum bid increment logic.

The contract was deployed and verified on the **Scroll Sepolia** testnet.

---

## 📌 Contract Overview

The `Auction` contract implements a time-limited auction with the following features:

- Minimum bid increment of **5%**
- Automatic extension if a bid is placed in the last **10 minutes**
- Ability to **partially refund** previous bids during the auction
- Final **refund (minus 2%)** for all non-winners once the auction ends
- Tracking of all bids and the current winning offer
- Owner-controlled auction finalization

---

## 🔧 Functions

| Function | Description |
|---------|-------------|
| `constructor()` | Initializes the auction with a start and stop time (7 days). Sets the deployer as the owner. |
| `bid()` | Allows users to place a bid. Must be at least 5% higher than the current winning bid. Extends time if within 10 minutes of deadline. |
| `showWinner()` | Returns the current highest bid and the corresponding bidder. |
| `showOffers()` | Returns an array with all bids (amount and bidder address). |
| `partialRefund()` | Lets a user withdraw all their previous bids (except the most recent one) during the auction. |
| `refund()` | Can only be called by the contract owner after the auction ends. Refunds all non-winners (with a 2% fee). |

---

## 🧮 Variables

| Variable | Type | Description |
|----------|------|-------------|
| `owner` | `address` | The contract's owner (set at deployment). |
| `startTime` | `uint256` | Timestamp when the auction starts. |
| `stopTime` | `uint256` | Timestamp when the auction ends. May be extended. |
| `AUCTION_DURATION` | `uint256 (constant)` | Duration of the auction (7 days). |
| `EXTENSION_TIME` | `uint256 (constant)` | Amount of time added if a late bid is placed (10 minutes). |
| `MIN_BID_INCREMENT_PERCENT` | `uint256 (constant)` | Required increment over the previous bid (5%). |
| `REFUND_FEE_PERCENT` | `uint256 (constant)` | Fee applied on final refunds for non-winners (2%). |
| `winner` | `Bidder struct` | Tracks the current winning bid and bidder. |
| `bids` | `Bidder[]` | Array containing all placed bids. |
| `userBids` | `mapping(address => uint256[])` | Stores all individual bid amounts per user. |
| `refundableAmount` | `mapping(address => uint256)` | Total amount that can be refunded to each user. |
| `hasWithdrawn` | `mapping(address => bool)` | Tracks whether a user has already received their final refund. |
| `auctionEnded` | `bool` | Becomes `true` once the owner finalizes the auction. |

---

## 📢 Events

| Event | Description |
|-------|-------------|
| `NewOffer(address bidder, uint256 amount)` | Emitted when a new valid bid is placed. |
| `AuctionEnded(address winner, uint256 amount)` | Emitted when the auction is finalized and a winner is determined. |
| `PartialRefund(address bidder, uint256 amount)` | Emitted when a user claims a partial refund during the auction. |

---

## ✅ Deployment Info

- **Network**: Scroll Sepolia
- **Compiler version**: `0.8.20`
- **Optimization**: Disabled
- **Contract Address**: [`0x4e3C39D8D679DECa7E1bcD7CA7589B3B9d4EaEDc`](https://sepolia.scrollscan.dev/address/0x4e3C39D8D679DECa7E1bcD7CA7589B3B9d4EaEDc)
- **License**: MIT

---

## 👨‍🔬 Testing Instructions (optional)

> You can interact with the contract using [Remix](https://remix.ethereum.org):
1. Load the verified contract using the "At Address" button in the **Deploy & Run Transactions** tab.
2. Call `bid()` with a value (e.g., `1 ether`, then `1.06 ether`, etc.).
3. Check the current winner with `showWinner()`.
4. Use `partialRefund()` to recover previous bids before the auction ends.
5. Once time has passed or the auction ends, call `refund()` as the owner.

---

## 📄 License

This project is licensed under the MIT License.
