const { assertEqualBN } = require('./helper/assert');
const { bufToStr, htlcERC20ArrayToObj, isSha256Hash, newSecretHashPair, nowSeconds, random32, txtradeId, txLoggedArgs } = require('./helper/utils');

const DvP = artifacts.require('./DvP');
const CommodityTokenContract = artifacts.require('AliceERC721');
const PaymentTokenContract = artifacts.require('BobERC20');

contract('Atomic DvP', (accounts) => {
  const buyer = accounts[1];
  const seller = accounts[2];
  const tokenSupply = 1000;
  const buyerInitialBalance = 100;

  let dvp, paymentToken, assetToken;

  // some testing data
  const hourSeconds = 3600;
  const timeLock1Hour = nowSeconds() + hourSeconds;
  const tokenAmount = 5;
  const EMPTY_BYTES = '0x0000000000000000000000000000000000000000000000000000000000000000';

  const assertTokenBal = async (addr, tokenAmount, msg) => assertEqualBN(await paymentToken.balanceOf.call(addr), tokenAmount, msg ? msg : 'wrong token balance');

  before(async () => {
    dvp = await DvP.new();

    paymentToken = await PaymentTokenContract.new(tokenSupply);
    await paymentToken.transfer(buyer, buyerInitialBalance);
    await assertTokenBal(buyer, buyerInitialBalance, 'balance not transferred in before()');

    assetToken = await CommodityTokenContract.new();
    await assetToken.transfer(seller, 1);
    await assetToken.transfer(seller, 2);
  });

  it('newTradePayment() should create new trade and store correct details', async () => {
    const hashPair = newSecretHashPair();
    const newTradeTx = await newTradePayment({
      hashlock: hashPair.hash,
    });

    // check token balances
    assertTokenBal(buyer, buyerInitialBalance - tokenAmount);
    assertTokenBal(dvp.address, tokenAmount);

    // check event logs
    const logArgs = txLoggedArgs(newTradeTx);

    const tradeId = logArgs.tradeId;
    assert(isSha256Hash(tradeId));

    assert.equal(logArgs.sender, buyer);
    assert.equal(logArgs.receiver, seller);
    assert.equal(logArgs.payment.tokenContract, paymentToken.address);
    assert.equal(logArgs.payment.paymentAmount, tokenAmount);
    assert.equal(logArgs.hashlock, hashPair.hash);
    assert.equal(logArgs.timelock, timeLock1Hour);

    // // check htlc record
    // const contractArr = await dvp.getContract.call(tradeId);
    // const contract = htlcERC20ArrayToObj(contractArr);
    // assert.equal(contract.sender, sender);
    // assert.equal(contract.receiver, receiver);
    // assert.equal(contract.token, token.address);
    // assert.equal(contract.amount.toNumber(), tokenAmount);
    // assert.equal(contract.hashlock, hashPair.hash);
    // assert.equal(contract.timelock.toNumber(), timeLock1Hour);
    // assert.isFalse(contract.withdrawn);
    // assert.isFalse(contract.refunded);
    // assert.equal(contract.preimage, '0x0000000000000000000000000000000000000000000000000000000000000000');
  });

  it('newTradeAsset() should create new trade and store correct details', async () => {
    const hashPair = newSecretHashPair();
    const newTradeTx = await newTradeAsset({
      hashlock: hashPair.hash,
    });

    // check token balances
    assertTokenBal(seller, 1);
    assertTokenBal(dvp.address, tokenAmount);

    // check event logs
    const logArgs = txLoggedArgs(newTradeTx);

    const tradeId = logArgs.tradeId;
    assert(isSha256Hash(tradeId));

    assert.equal(logArgs.sender, seller);
    assert.equal(logArgs.receiver, buyer);
    assert.equal(logArgs.asset.tokenContract, assetToken.address);
    assert.equal(logArgs.asset.assetId, 1);
    assert.equal(logArgs.hashlock, hashPair.hash);
    assert.equal(logArgs.timelock, timeLock1Hour);

    // // check htlc record
    // const contractArr = await dvp.getContract.call(tradeId);
    // const contract = htlcERC20ArrayToObj(contractArr);
    // assert.equal(contract.sender, sender);
    // assert.equal(contract.receiver, receiver);
    // assert.equal(contract.token, token.address);
    // assert.equal(contract.amount.toNumber(), tokenAmount);
    // assert.equal(contract.hashlock, hashPair.hash);
    // assert.equal(contract.timelock.toNumber(), timeLock1Hour);
    // assert.isFalse(contract.withdrawn);
    // assert.isFalse(contract.refunded);
    // assert.equal(contract.preimage, '0x0000000000000000000000000000000000000000000000000000000000000000');
  });

  const newTradePayment = async ({ timelock = timeLock1Hour, hashlock = newSecretHashPair().hash } = {}) => {
    await paymentToken.approve(dvp.address, tokenAmount, { from: buyer });
    return dvp.newTradePayment(EMPTY_BYTES, seller, hashlock, timelock, paymentToken.address, tokenAmount, {
      from: buyer,
    });
  };

  const newTradeAsset = async ({ timelock = timeLock1Hour, hashlock = newSecretHashPair().hash } = {}) => {
    await assetToken.approve(dvp.address, 1, { from: seller });
    return dvp.newTradeAsset(EMPTY_BYTES, buyer, hashlock, timelock, assetToken.address, 1, {
      from: seller,
    });
  };
});
