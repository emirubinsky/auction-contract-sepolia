# 🕒 Smart Auction Contract

Welcome! This is a decentralized auction smart contract written in Solidity for the **Scroll Sepolia** testnet.

It supports time-based bidding with automatic deadline extensions, partial refund logic, and a fair winner selection mechanism. Users can participate by placing bids with ETH and retrieve their outbid offers either during or after the auction.

---

## 🔧 Smart Contract Functions

| Function           | Description                                                                 |
|--------------------|-----------------------------------------------------------------------------|
| `bid()`            | Place a bid at least 5% higher than the current top bid. Extends auction if close to ending. |
| `showWinner()`     | Returns the current highest bidder and the amount.                          |
| `showOffers()`     | Returns a list of all submitted bids.                                       |
| `refund()`         | Ends the auction and sends refunds (minus 2%) to all bidders except the winner. |
| `partialRefund()`  | Allows users to withdraw their older bids while the auction is still active. |

---

## 🧠 State Variables

### General
- `owner` – Address of the contract creator.
- `startTime` / `stopTime` – Auction timing control.
- `auctionEnded` – Boolean indicating whether the auction has been finalized.

### Constants
- `AUCTION_DURATION` – Duration of the auction (7 days).
- `EXTENSION_TIME` – Extra time added if a bid is placed near the end (10 minutes).
- `MIN_BID_INCREMENT_PERCENT` – Minimum bid increase (5%).
- `REFUND_FEE_PERCENT` – Refund fee (2%).

### Bidding
- `Bidder[] bids` – Array storing all bids and bidder addresses.
- `Bidder winner` – Tracks the highest bid and the leading bidder.

### User tracking
- `mapping(address => uint256[]) userBids` – Stores multiple bids per user.
- `mapping(address => uint256) refundableAmount` – Tracks how much each user can reclaim.
- `mapping(address => bool) hasWithdrawn` – Prevents duplicate withdrawals.

---

## 📣 Events

| Event                              | Description                                                             |
|------------------------------------|-------------------------------------------------------------------------|
| `NewOffer(address bidder, uint256 amount)` | Emitted whenever a new bid is placed.                         |
| `AuctionEnded(address winner, uint256 amount)` | Emitted when the auction is closed and winner is declared.     |
| `PartialRefund(address bidder, uint256 amount)` | Emitted when a user withdraws their old bids before auction ends. |

---

## 🧪 How to Use (Remix)

1. Deploy the contract to Scroll Sepolia using Remix and Metamask.
2. Switch to the deployed contract instance under “Deployed Contracts”.
3. To place a bid:  
   - In the "Value" field, enter e.g. `1` and select `ether`, then click `bid()`.
4. Use `showWinner()` to see the current top bidder and amount.
5. As the contract owner, end the auction by calling `refund()` after time has passed.
6. Users who were outbid can recover previous funds using `partialRefund()`.

---

## 🛡️ Security Notes

- ❗ Bids are only accepted if they are at least **5% higher** than the current highest.
- ❗ The auction can only be ended **once**, and only by the **contract owner**.
- ✅ Refunds are calculated **excluding** a 2% fee.
- ✅ Bidders can retrieve previous bids **before** auction ends, avoiding locked funds.

---

Feel free to explore and test the contract on Scroll Sepolia!
