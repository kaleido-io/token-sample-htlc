# hashed-timelock-contract-ethereum

[Hashed Timelock Contracts](https://en.bitcoin.it/wiki/Hashed_Timelock_Contracts) (HTLCs) for Ethereum:

- [HashedTimelockERC20.sol](contracts/HashedTimelockERC20.sol) - HTLC for ERC20 tokens
- [HashedTimelockERC721.sol](contracts/HashedTimelockERC721.sol) - HTLC for ERC721 tokens

Use these contracts for creating HTLCs on the Ethereum side of a cross chain atomic swap.

## Run Tests

```
$ npm i
$ npx hardhat test
  Contract: Atomic DvP
Your project has Truffle migrations, which have to be turned into a fixture to run your tests with Hardhat
    ✔ newTradePayment() should create new trade and store correct details
    ✔ newTradeAsset() should create new trade and store correct details

  Contract: HashedTimelockERC20
    ✔ newContract() should create new contract and store correct details
    ✔ newContract() should fail when no token transfer approved
    ✔ newContract() should fail when token amount is 0
    ✔ newContract() should fail when tokens approved for some random account
    ✔ newContract() should fail when the timelock is in the past
    ✔ newContract() should reject a duplicate contract request
    ✔ withdraw() should send receiver funds when given the correct secret preimage
    ✔ withdraw() should fail if preimage does not hash to hashX
    ✔ withdraw() should fail if caller is not the receiver
    ✔ refund() should pass after timelock expiry
    ✔ refund() should fail before the timelock expiry
    ✔ getContract() returns empty record when contract doesn't exist

  Contract: HashedTimelock swap between two ERC20 tokens
    ✔ Step 1: Alice sets up a swap with Bob in the AliceERC20 contract
    ✔ Step 2: Bob sets up a swap with Alice in the BobERC20 contract
    ✔ Step 3: Alice as the initiator withdraws from the BobERC20 with the secret
    ✔ Step 4: Bob as the counterparty withdraws from the AliceERC20 with the secret learned from Alice's withdrawal
    Test the refund scenario:
      ✔ the swap is set up with 5sec timeout on both sides

  Contract: HashedTimelock swap between ERC721 token and ERC20 token (Delivery vs. Payment)
    ✔ Step 1: Alice sets up a swap with Bob to transfer the Commodity token #1
    ✔ Step 2: Bob sets up a swap with Alice in the payment contract
    ✔ Step 3: Alice as the initiator withdraws from the BobERC721 with the secret
    ✔ Step 4: Bob as the counterparty withdraws from the AliceERC721 with the secret learned from Alice's withdrawal
    Test the refund scenario:
      ✔ the swap is set up with 10 sec timeout on both sides

  Contract: HashedTimelock swap between two ERC721 tokens
    ✔ Step 1: Alice sets up a swap with Bob in the AliceERC721 contract
    ✔ Step 2: Bob sets up a swap with Alice in the BobERC721 contract
    ✔ Step 3: Alice as the initiator withdraws from the BobERC721 with the secret
    ✔ Step 4: Bob as the counterparty withdraws from the AliceERC721 with the secret learned from Alice's withdrawal
    Test the refund scenario:
      ✔ the swap is set up with 10 sec timeout on both sides


  29 passing (723ms)
```

## Protocol - ERC20

### Main flow

![](docs/sequence-diagram-htlc-erc20-success.png?raw=true)

### Timelock expires

![](docs/sequence-diagram-htlc-erc20-refund.png?raw=true)

## Interface

### HashedTimelockERC20

1.  `newContract(receiverAddress, hashlock, timelock, tokenContract, amount)` create new HTLC with given receiver, hashlock, expiry, ERC20 token contract address and amount of tokens
2.  `withdraw(contractId, preimage)` claim funds revealing the preimage
3.  `refund(contractId)` if withdraw was not called the contract creator can get a refund by calling this some time after the time lock has expired.

See [test/htlcERC20.js](test/htlcERC20.js) for examples of interacting with the contract from javascript.

### HashedTimelockERC721

1.  `newContract(receiverAddress, hashlock, timelock, tokenContract, tokenId)` create new HTLC with given receiver, hashlock, expiry, ERC20 token contract address and the token to transfer
2.  `withdraw(contractId, preimage)` claim funds revealing the preimage
3.  `refund(contractId)` if withdraw was not called the contract creator can get a refund by calling this some time after the time lock has expired.

See [test/htlcERC721.js](test/htlcERC721ToERC721.js) for examples of interacting with the contract from javascript.
