pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./HashedTimelockBase.sol";
import "hardhat/console.sol";

/**
 * @title AtomicDvP orchestrates atomic swaps of assets between two parties. It assumes
 *     that the asset (ERC721) and payment (ERC20) contracts are both deployed to the
 *     same blockchain as the AtomicDvP contract.
 *
 * Protocol:
 *
 *  1) newContract(receiver, hashlock, timelock, tokenContract, amount) - a
 *      sender calls this to create a new HTLC on a given token (tokenContract)
 *       for a given amount. A 32 byte contract id is returned
 *  2) withdraw(contractId, preimage) - once the receiver knows the preimage of
 *      the hashlock hash they can claim the tokens with this function
 *  3) refund() - after timelock has expired and if the receiver did not
 *      withdraw the tokens the sender / creater of the HTLC can get their tokens
 *      back with this function.
 */
contract AtomicDvP is HashedTimelockBase {
    event NewTrade(
        bytes32 indexed tradeId,
        address indexed sender,
        address indexed receiver,
        PaymentDetail payment,
        AssetDetail asset,
        bytes32 hashlock,
        uint256 timelock
    );

    constructor() {}

    modifier tokensTransferable(
        address _token,
        address _sender,
        uint256 _paymentAmount,
        uint256 _assetId
    ) {
        console.log("paymentAmount", _paymentAmount);
        console.log("assetId", _assetId);
        require(
            _paymentAmount > 0 || _assetId > 0,
            "token amount and assetId must not be both 0"
        );
        if (_paymentAmount > 0) {
            require(
                ERC20(_token).allowance(_sender, address(this)) >=
                    _paymentAmount,
                "token allowance must be >= amount"
            );
        } else {
            require(
                ERC721(_token).getApproved(_assetId) == address(this),
                "The HTLC contract must have been designated an approved spender for the tokenId"
            );
        }
        _;
    }

    function newTradePayment(
        bytes32 _tradeId,
        address _receiver,
        bytes32 _hashlock,
        uint256 _timelock,
        address _paymentContract,
        uint256 _paymentAmount
    )
        external
        tokensTransferable(_paymentContract, msg.sender, _paymentAmount, 0)
        futureTimelock(_timelock)
        returns (bytes32 tradeId)
    {
        LockTrade memory trade;
        if (_tradeId == bytes32(0)) {
            // new trade, calculate the tradeId
            tradeId = sha256(
                abi.encodePacked(
                    msg.sender,
                    _receiver,
                    _paymentContract,
                    _paymentAmount,
                    _hashlock,
                    _timelock
                )
            );
            // Reject if a contract already exists with the same parameters. The
            // sender must change one of these parameters (ideally providing a
            // different _hashlock).
            if (haveTrade(tradeId)) revert();

            trade = LockTrade(
                msg.sender,
                _receiver,
                PaymentDetail(_paymentContract, _paymentAmount),
                AssetDetail(address(0), 0),
                _hashlock,
                _timelock,
                false,
                false,
                0x0
            );
        } else {
            tradeId = _tradeId;
            trade = trades[_tradeId];
            trade.payment = PaymentDetail(_paymentContract, _paymentAmount);
        }
        trades[tradeId] = trade;

        if (
            !ERC20(_paymentContract).transferFrom(
                msg.sender,
                address(this),
                _paymentAmount
            )
        ) revert();

        emit NewTrade(
            tradeId,
            msg.sender,
            _receiver,
            trade.payment,
            trade.asset,
            _hashlock,
            _timelock
        );
    }

    function newTradeAsset(
        bytes32 _tradeId,
        address _receiver,
        bytes32 _hashlock,
        uint256 _timelock,
        address _assetContract,
        uint256 _assetId
    )
        external
        tokensTransferable(_assetContract, msg.sender, 0, _assetId)
        futureTimelock(_timelock)
        returns (bytes32 tradeId)
    {
        LockTrade memory trade;
        if (_tradeId == bytes32(0)) {
            // new trade, calculate the tradeId
            tradeId = sha256(
                abi.encodePacked(
                    msg.sender,
                    _receiver,
                    _assetContract,
                    _assetId,
                    _hashlock,
                    _timelock
                )
            );
            // Reject if a contract already exists with the same parameters. The
            // sender must change one of these parameters (ideally providing a
            // different _hashlock).
            if (haveTrade(tradeId)) revert();

            trade = LockTrade(
                msg.sender,
                _receiver,
                PaymentDetail(address(0), 0),
                AssetDetail(_assetContract, _assetId),
                _hashlock,
                _timelock,
                false,
                false,
                0x0
            );
        } else {
            tradeId = _tradeId;
            trade = trades[_tradeId];
            trade.asset = AssetDetail(_assetContract, _assetId);
        }
        trades[tradeId] = trade;

        ERC721(_assetContract).transferFrom(
            msg.sender,
            address(this),
            _assetId
        );

        emit NewTrade(
            tradeId,
            msg.sender,
            _receiver,
            trade.payment,
            trade.asset,
            _hashlock,
            _timelock
        );
    }
}
