# Smart Auction Contract

This repository contains a decentralized auction smart contract built in Solidity, deployed on the Scroll Sepolia testnet. The contract facilitates time-limited bidding rounds with automatic deadline extensions, secure refunds for non-winning participants, and transparent winner selection. It includes features such as partial withdrawals, bid tracking, and emergency fund recovery.

## **Overview**

The contract implements the following core features:

- Accepts bids only if they exceed the current top bid by a minimum percentage (5%).
- Automatically extends the auction deadline if a bid is placed close to the end (within 10 minutes).
- Allows non-winning bidders to reclaim their funds after the auction ends, with a 2% refund fee applied.
- Enables participants to partially withdraw overbid amounts before the auction ends, excluding their most recent bid.
- Includes an emergency withdrawal function for the contract owner to recover ETH in special situations.
- Designed to be non-reentrant and used for a single auction cycle.

## **Functions**

| **Name**              | **Description** |
|------------------------|------------------|
| `bid()`                | Places a new bid. Must exceed the current highest bid by at least 5%. Automatically extends the auction if placed within the last 10 minutes. |
| `showWinner()`         | Returns the address and bid amount of the current highest bidder. |
| `showOffers()`         | Displays the list of all submitted bids. |
| `refund()`             | Can be called once by the contract owner after the auction ends. Refunds all bidders except the winner, applying a 2% deduction. |
| `partialRefund()`      | Allows users to withdraw previous (outbid) amounts before the auction ends, keeping only their last bid active. |
| `emergencyWithdraw()`  | Transfers the remaining ETH in the contract to the owner. Only callable by the owner and only if there is a balance. |

## **State Variables**

### **General**

- `owner`: Address of the contract deployer.
- `startTime`: Timestamp when the auction started.
- `stopTime`: Timestamp when the auction is scheduled to end.
- `auctionEnded`: Boolean flag indicating whether the auction has been finalized.

### **Constants**

- `AUCTION_DURATION`: Fixed auction duration (7 days).
- `EXTENSION_TIME`: Additional time added to the deadline when late bids are placed (10 minutes).
- `MIN_BID_INCREMENT_PERCENT`: Minimum percentage required to exceed the current top bid (5%).
- `REFUND_FEE_PERCENT`: Flat fee deducted from refunds (2%).

### **Bidding Logic**

- `bids`: An array of all `Bidder` structs, each including the bid amount and bidder address.
- `winner`: Struct holding the address and amount of the current highest bid.

### **User Tracking**

- `userBids`: Mapping that stores an array of bid amounts for each user.
- `refundableAmount`: Tracks how much a user can reclaim.
- `hasWithdrawn`: Mapping to ensure each user can receive a refund only once.

## **Events**

| **Event**                           | **Description** |
|-------------------------------------|------------------|
| `NewOffer(address, uint256)`        | Emitted every time a valid bid is placed. |
| `AuctionEnded(address, uint256)`    | Emitted when the auction is finalized and the winner is confirmed. |
| `PartialRefund(address, uint256)`   | Emitted when a user reclaims their earlier bids (excluding the latest) before the auction ends. |
| `EmergencyWithdrawal(address, uint256)` | Emitted when the owner withdraws the full contract balance. |

## **Usage Instructions (Remix + Metamask)**

### **Deploy the Contract**

1. Open [Remix IDE](https://remix.ethereum.org).
2. Use the Solidity compiler version `^0.8.20`.
3. Select the **Injected Provider - Metamask** environment.
4. Ensure you are connected to the **Scroll Sepolia** testnet.
5. Deploy the contract.

### **Interact with the Contract**

- Use the `bid()` function by entering a value (e.g., `1 ether`) and submitting the transaction.
- Track the current winner with `showWinner()`.
- View all submitted bids using `showOffers()`.

### **Finalizing the Auction**

After the auction has ended (either naturally by time or manually by calling `refund()`), the contract owner can trigger `refund()` to process refunds for non-winning bidders. A 2% fee will be deducted.

### **Early Withdrawals**

Participants may call `partialRefund()` **before** the auction ends to reclaim their older bids (all except the last one). This helps users recover capital during active bidding.

### **Emergency Withdrawals**

If needed, the contract owner can call `emergencyWithdraw()` to transfer all ETH in the contract to their address. This is intended for emergency recovery scenarios only.

## **Security Considerations**

- Bids must exceed the current highest bid by at least 5% to discourage spam and ensure fair competition.
- Refunds are allowed only once per user and cannot be duplicated due to the `hasWithdrawn` flag.
- The contract uses `block.timestamp` for time logic. It is not vulnerable to manipulation in most L2 environments, including Scroll.
- The `refund()` function is callable only once and only by the owner, preventing multiple executions.
- ETH transfers are done via `transfer`, protecting against reentrancy attacks.

## **Testing Environment**

- **Network:** Scroll Sepolia (L2 Testnet)
- **Solidity Version:** ^0.8.20
- **Tooling:** Remix IDE, Metamask, Etherscan (for contract verification)

## **License**

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
