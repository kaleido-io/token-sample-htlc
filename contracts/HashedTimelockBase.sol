pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title Hashed Timelock contract (HTLC)
 *
 * This contract provides a way to create and keep HTLCs for ERC721 tokens.
 *
 * See HashedTimelock.sol for a contract that provides the same functions
 * for the native ETH token.
 *
 * Protocol:
 *
 *  1) newContract(receiver, hashlock, timelock, tokenContract, tokenId) - a
 *      sender calls this to create a new HTLC on a given token (tokenContract)
 *       for a given token ID. A 32 byte contract id is returned
 *  2) withdraw(contractId, preimage) - once the receiver knows the preimage of
 *      the hashlock hash they can claim the tokens with this function
 *  3) refund() - after timelock has expired and if the receiver did not
 *      withdraw the tokens the sender / creater of the HTLC can get their tokens
 *      back with this function.
 */
contract HashedTimelockBase {
    struct PaymentDetail {
        address tokenContract;
        uint256 paymentAmount;
    }

    struct AssetDetail {
        address tokenContract;
        uint256 assetId;
    }

    struct LockTrade {
        address sender;
        address receiver;
        PaymentDetail payment;
        AssetDetail asset;
        bytes32 hashlock;
        uint256 timelock;
        bool withdrawn;
        bool refunded;
        bytes32 preimage;
    }

    mapping(bytes32 => LockTrade) trades;

    modifier futureTimelock(uint256 _time) {
        // only requirement is the timelock time is after the last blocktime (now).
        // probably want something a bit further in the future then this.
        // but this is still a useful sanity check:
        require(_time > block.timestamp, "timelock time must be in the future");
        _;
    }
    modifier tradeExists(bytes32 _tradeId) {
        require(haveTrade(_tradeId), "contractId does not exist");
        _;
    }
    modifier hashlockMatches(bytes32 _tradeId, bytes32 _x) {
        require(
            trades[_tradeId].hashlock == sha256(abi.encodePacked(_x)),
            "hashlock hash does not match"
        );
        _;
    }
    modifier withdrawable(bytes32 _tradeId) {
        require(
            trades[_tradeId].receiver == msg.sender,
            "withdrawable: not receiver"
        );
        require(
            trades[_tradeId].withdrawn == false,
            "withdrawable: already withdrawn"
        );
        // if we want to disallow claim to be made after the timeout, uncomment the following line
        // require(trades[_tradeId].timelock > now, "withdrawable: timelock time must be in the future");
        _;
    }
    modifier refundable(bytes32 _tradeId) {
        require(
            trades[_tradeId].sender == msg.sender,
            "refundable: not sender"
        );
        require(
            trades[_tradeId].refunded == false,
            "refundable: already refunded"
        );
        require(
            trades[_tradeId].withdrawn == false,
            "refundable: already withdrawn"
        );
        require(
            trades[_tradeId].timelock <= block.timestamp,
            "refundable: timelock not yet passed"
        );
        _;
    }

    /**
     * @dev Is there a trade with id _tradeId.
     * @param _tradeId Id into trades mapping.
     */
    function haveTrade(bytes32 _tradeId) internal view returns (bool exists) {
        exists = (trades[_tradeId].sender != address(0));
    }
}
