pragma solidity ^0.4.24;

/// @title Raiden MicroTransfer Channels Contract.
contract RaidenMicroTransferChannels {

    /*
     *  Data structures
     */

    // The only role of the owner_address is to add or remove trusted contracts
    address public owner_address;

    // Number of blocks to wait from an uncooperativeClose initiated by the sender
    // in order to give the receiver a chance to respond with a balance proof
    // in case the sender cheats. After the challenge period, the sender can settle
    // and delete the channel.
    uint32 public challenge_period;

    // Contract semantic version
    string public constant version = '0.2.0';

    // We temporarily limit total token deposits in a channel to 100 tokens with 18 decimals.
    // This was calculated just for RDN with its current (as of 30/11/2017) price and should
    // not be considered to be the same for other tokens.
    // This is just for the bug bounty release, as a safety measure.
    uint256 public constant channel_deposit_bugbounty_limit = 10 ** 18 * 100;

    mapping (bytes32 => Channel) public channels;
    mapping (bytes32 => ClosingRequest) public closing_requests;
    mapping (address => bool) public trusted_contracts;
    mapping (bytes32 => uint256) public withdrawn_balances;

    // 24 bytes (deposit) + 4 bytes (block number)
    struct Channel {
        // uin256 size of the deposit
        uint256 deposit;

        // Block number at which the channel was opened. Used in creating
        // a unique identifier for the channel between a sender and receiver.
        // Supports creation of multiple channels between the 2 parties and prevents
        // replay of messages in later channels.
        uint32 open_block_number;
    }

    // 24 bytes (deposit) + 4 bytes (block number)
    struct ClosingRequest {
        // Number of tokens owed by the sender when closing the channel.
        uint256 closing_balance;

        // Block number at which the challenge period ends, in case it has been initiated.
        uint32 settle_block_number;
    }

    /*
     * Modifiers
     */

    modifier isOwner() {
        require(msg.sender == owner_address);
        _;
    }

    modifier isTrustedContract() {
        require(trusted_contracts[msg.sender]);
        _;
    }

    /*
     *  Events
     */

    event ChannelCreated(
        address indexed _sender_address,
        address indexed _receiver_address,
        uint256 _deposit);
    event ChannelToppedUp (
        address indexed _sender_address,
        address indexed _receiver_address,
        uint32 indexed _open_block_number,
        uint256 _added_deposit);
    event ChannelCloseRequested(
        address indexed _sender_address,
        address indexed _receiver_address,
        uint32 indexed _open_block_number,
        uint256 _balance);
    event ChannelSettled(
        address indexed _sender_address,
        address indexed _receiver_address,
        uint32 indexed _open_block_number,
        uint256 _balance,
        uint256 _receiver_tokens);
    event ChannelWithdraw(
        address indexed _sender_address,
        address indexed _receiver_address,
        uint32 indexed _open_block_number,
        uint256 _withdrawn_balance);
    event TrustedContract(
        address indexed _trusted_contract_address,
        bool _trusted_status);


    /*
     *  Constructor
     */

    /// @notice Constructor for creating the uRaiden microtransfer channels contract.
    /// @param _challenge_period A fixed number of blocks representing the challenge period.
    /// We enforce a minimum of 500 blocks waiting period.
    /// after a sender requests the closing of the channel without the receiver's signature.
    /// @param _trusted_contracts Array of contract addresses that can be trusted to
    /// open and top up channels on behalf of a sender.
    constructor(
        uint32 _challenge_period,
        address[] _trusted_contracts)
        public
    {
        require(_challenge_period >= 500);

        challenge_period = _challenge_period;
        owner_address = msg.sender;
        addTrustedContracts(_trusted_contracts);
    }

    /*
     *  External functions
     */


    /// @notice Creates a new channel between `msg.sender` and `_receiver_address` and transfers
    /// the `_deposit` token deposit to this contract. Compatibility with ERC20 tokens.
    /// @param _receiver_address The address that receives tokens.
    function createChannel(address _receiver_address) external payable {
        createChannelPrivate(msg.sender, _receiver_address, msg.value);
    }

    /// @notice Function that allows a delegate contract to create a new channel between
    /// `_sender_address` and `_receiver_address` and transfers the token deposit to this contract.
    /// Can only be called by a trusted contract. Compatibility with ERC20 tokens.
    /// @param _sender_address The sender's address in behalf of whom the delegate sends tokens.
    /// @param _receiver_address The address that receives tokens.
    function createChannelDelegate(
        address _sender_address,
        address _receiver_address)
        isTrustedContract
        external
        payable
    {
        createChannelPrivate(_sender_address, _receiver_address, msg.value);
    }

    /// @notice Increase the channel deposit with `_added_deposit`.
    /// @param _receiver_address The address that receives tokens.
    /// @param _open_block_number The block number at which a channel between the
    /// sender and receiver was created.
    function topUp(
        address _receiver_address,
        uint32 _open_block_number)
        external
        payable
    {
        updateInternalBalanceStructs(
            msg.sender,
            _receiver_address,
            _open_block_number,
            msg.value
        );
    }

    /// @notice Function that allows a delegate contract to increase the channel deposit
    /// with `_added_deposit`. Can only be called by a trusted contract. Compatibility with ERC20 tokens.
    /// @param _sender_address The sender's address in behalf of whom the delegate sends tokens.
    /// @param _receiver_address The address that receives tokens.
    /// @param _open_block_number The block number at which a channel between the
    /// sender and receiver was created.
    function topUpDelegate(
        address _sender_address,
        address _receiver_address,
        uint32 _open_block_number)
        isTrustedContract
        external
        payable
    {
        updateInternalBalanceStructs(
            _sender_address,
            _receiver_address,
            _open_block_number,
            msg.value
        );
    }

    /// @notice Allows channel receiver to withdraw tokens.
    /// @param _open_block_number The block number at which a channel between the
    /// sender and receiver was created.
    /// @param _balance Partial or total amount of tokens owed by the sender to the receiver.
    /// Has to be smaller or equal to the channel deposit. Has to match the balance value from
    /// `_balance_msg_sig` - the balance message signed by the sender.
    /// Has to be smaller or equal to the channel deposit.
    /// @param _balance_msg_sig The balance message signed by the sender.
    function withdraw(
        uint32 _open_block_number,
        uint256 _balance,
        bytes _balance_msg_sig)
        external
    {
        require(_balance > 0);

        // Derive sender address from signed balance proof
        address sender_address = extractBalanceProofSignature(
            msg.sender,
            _open_block_number,
            _balance,
            _balance_msg_sig
        );

        bytes32 key = getKey(sender_address, msg.sender, _open_block_number);

        // Make sure the channel exists
        require(channels[key].open_block_number > 0);

        // Make sure the channel is not in the challenge period
        require(closing_requests[key].settle_block_number == 0);

        require(_balance <= channels[key].deposit);
        require(withdrawn_balances[key] < _balance);

        uint256 remaining_balance = _balance - withdrawn_balances[key];
        withdrawn_balances[key] = _balance;

        // Send the remaining balance to the receiver
        msg.sender.transfer(remaining_balance);

        emit ChannelWithdraw(sender_address, msg.sender, _open_block_number, remaining_balance);
    }

    /// @notice Function called by the sender, receiver or a delegate, with all the needed
    /// signatures to close the channel and settle immediately.
    /// @param _receiver_address The address that receives tokens.
    /// @param _open_block_number The block number at which a channel between the
    /// sender and receiver was created.
    /// @param _balance The amount of tokens owed by the sender to the receiver.
    /// @param _balance_msg_sig The balance message signed by the sender.
    /// @param _closing_sig The receiver's signed balance message, containing the sender's address.
    function cooperativeClose(
        address _receiver_address,
        uint32 _open_block_number,
        uint256 _balance,
        bytes _balance_msg_sig,
        bytes _closing_sig)
        external
    {
        // Derive sender address from signed balance proof
        address sender = extractBalanceProofSignature(
            _receiver_address,
            _open_block_number,
            _balance,
            _balance_msg_sig
        );

        // Derive receiver address from closing signature
        address receiver = extractClosingSignature(
            sender,
            _open_block_number,
            _balance,
            _closing_sig
        );
        require(receiver == _receiver_address);

        // Both signatures have been verified and the channel can be settled.
        settleChannel(sender, receiver, _open_block_number, _balance);
    }

    /// @notice Sender requests the closing of the channel and starts the challenge period.
    /// This can only happen once.
    /// @param _receiver_address The address that receives tokens.
    /// @param _open_block_number The block number at which a channel between
    /// the sender and receiver was created.
    /// @param _balance The amount of tokens owed by the sender to the receiver.
    function uncooperativeClose(
        address _receiver_address,
        uint32 _open_block_number,
        uint256 _balance)
        external
    {
        bytes32 key = getKey(msg.sender, _receiver_address, _open_block_number);

        require(channels[key].open_block_number > 0);
        require(closing_requests[key].settle_block_number == 0);
        require(_balance <= channels[key].deposit);

        // Mark channel as closed
        closing_requests[key].settle_block_number = uint32(block.number) + challenge_period;
        require(closing_requests[key].settle_block_number > block.number);
        closing_requests[key].closing_balance = _balance;
        emit ChannelCloseRequested(msg.sender, _receiver_address, _open_block_number, _balance);
    }


    /// @notice Function called by the sender after the challenge period has ended, in order to
    /// settle and delete the channel, in case the receiver has not closed the channel himself.
    /// @param _receiver_address The address that receives tokens.
    /// @param _open_block_number The block number at which a channel between
    /// the sender and receiver was created.
    function settle(address _receiver_address, uint32 _open_block_number) external {
        bytes32 key = getKey(msg.sender, _receiver_address, _open_block_number);

        // Make sure an uncooperativeClose has been initiated
        require(closing_requests[key].settle_block_number > 0);

        // Make sure the challenge_period has ended
        require(block.number > closing_requests[key].settle_block_number);

        settleChannel(msg.sender, _receiver_address, _open_block_number,
            closing_requests[key].closing_balance
        );
    }

    /// @notice Function for retrieving information about a channel.
    /// @param _sender_address The address that sends tokens.
    /// @param _receiver_address The address that receives tokens.
    /// @param _open_block_number The block number at which a channel between the
    /// sender and receiver was created.
    /// @return Channel information: unique_identifier, deposit, settle_block_number,
    /// closing_balance, withdrawn balance).
    function getChannelInfo(
        address _sender_address,
        address _receiver_address,
        uint32 _open_block_number)
        external
        view
        returns (bytes32, uint256, uint32, uint256, uint256)
    {
        bytes32 key = getKey(_sender_address, _receiver_address, _open_block_number);
        require(channels[key].open_block_number > 0);

        return (
            key,
            channels[key].deposit,
            closing_requests[key].settle_block_number,
            closing_requests[key].closing_balance,
            withdrawn_balances[key]
        );
    }

    /*
     *  Public functions
     */

    /// @notice Function for adding trusted contracts. Can only be called by owner_address.
    /// @param _trusted_contracts Array of contract addresses that can be trusted to
    /// open and top up channels on behalf of a sender.
    function addTrustedContracts(address[] _trusted_contracts) isOwner public {
        for (uint256 i = 0; i < _trusted_contracts.length; i++) {
            if (addressHasCode(_trusted_contracts[i])) {
                trusted_contracts[_trusted_contracts[i]] = true;
                emit TrustedContract(_trusted_contracts[i], true);
            }
        }
    }

    /// @notice Function for removing trusted contracts. Can only be called by owner_address.
    /// @param _trusted_contracts Array of contract addresses to be removed from
    /// the trusted_contracts mapping.
    function removeTrustedContracts(address[] _trusted_contracts) isOwner public {
        for (uint256 i = 0; i < _trusted_contracts.length; i++) {
            if (trusted_contracts[_trusted_contracts[i]]) {
                trusted_contracts[_trusted_contracts[i]] = false;
                emit TrustedContract(_trusted_contracts[i], false);
            }
        }
    }

    /// @notice Returns the sender address extracted from the balance proof.
    /// dev Works with eth_signTypedData https://github.com/ethereum/EIPs/pull/712.
    /// @param _receiver_address The address that receives tokens.
    /// @param _open_block_number The block number at which a channel between the
    /// sender and receiver was created.
    /// @param _balance The amount of tokens owed by the sender to the receiver.
    /// @param _balance_msg_sig The balance message signed by the sender.
    /// @return Address of the balance proof signer.
    function extractBalanceProofSignature(
        address _receiver_address,
        uint32 _open_block_number,
        uint256 _balance,
        bytes _balance_msg_sig)
        public
        view
        returns (address)
    {
        // The variable names from below will be shown to the sender when signing
        // the balance proof, so they have to be kept in sync with the Dapp client.
        // The hashed strings should be kept in sync with this function's parameters
        // (variable names and types).
        // ! Note that EIP712 might change how hashing is done, triggering a
        // new contract deployment with updated code.
        bytes32 message_hash = keccak256(
            keccak256(
                'string message_id',
                'address receiver',
                'uint32 block_created',
                'uint256 balance',
                'address contract'
            ),
            keccak256(
                'Sender balance proof signature',
                _receiver_address,
                _open_block_number,
                _balance,
                address(this)
            )
        );

        // Derive address from signature
        address signer = ecverify(message_hash, _balance_msg_sig);
        return signer;
    }

    /// @dev Returns the receiver address extracted from the closing signature.
    /// Works with eth_signTypedData https://github.com/ethereum/EIPs/pull/712.
    /// @param _sender_address The address that sends tokens.
    /// @param _open_block_number The block number at which a channel between the
    /// sender and receiver was created.
    /// @param _balance The amount of tokens owed by the sender to the receiver.
    /// @param _closing_sig The receiver's signed balance message, containing the sender's address.
    /// @return Address of the closing signature signer.
    function extractClosingSignature(
        address _sender_address,
        uint32 _open_block_number,
        uint256 _balance,
        bytes _closing_sig)
        public
        view
        returns (address)
    {
        // The variable names from below will be shown to the sender when signing
        // the balance proof, so they have to be kept in sync with the Dapp client.
        // The hashed strings should be kept in sync with this function's parameters
        // (variable names and types).
        // ! Note that EIP712 might change how hashing is done, triggering a
        // new contract deployment with updated code.
        bytes32 message_hash = keccak256(
            keccak256(
                'string message_id',
                'address sender',
                'uint32 block_created',
                'uint256 balance',
                'address contract'
            ),
            keccak256(
                'Receiver closing signature',
                _sender_address,
                _open_block_number,
                _balance,
                address(this)
            )
        );

        // Derive address from signature
        address signer = ecverify(message_hash, _closing_sig);
        return signer;
    }

    /// @notice Returns the unique channel identifier used in the contract.
    /// @param _sender_address The address that sends tokens.
    /// @param _receiver_address The address that receives tokens.
    /// @param _open_block_number The block number at which a channel between the
    /// sender and receiver was created.
    /// @return Unique channel identifier.
    function getKey(
        address _sender_address,
        address _receiver_address,
        uint32 _open_block_number)
        public
        pure
        returns (bytes32 data)
    {
        return keccak256(abi.encodePacked(_sender_address, _receiver_address, _open_block_number));
    }

    /*
     *  Private functions
     */

    /// @dev Creates a new channel between a sender and a receiver.
    /// @param _sender_address The address that sends tokens.
    /// @param _receiver_address The address that receives tokens.
    /// @param _deposit The amount of eve that the sender escrows.
    function createChannelPrivate(
        address _sender_address,
        address _receiver_address,
        uint256 _deposit)
        private
    {
        require(_deposit <= channel_deposit_bugbounty_limit);

        uint32 open_block_number = uint32(block.number);

        // Create unique identifier from sender, receiver and current block number
        bytes32 key = getKey(_sender_address, _receiver_address, open_block_number);

        require(channels[key].deposit == 0);
        require(channels[key].open_block_number == 0);
        require(closing_requests[key].settle_block_number == 0);

        // Store channel information
        channels[key] = Channel({deposit: _deposit, open_block_number: open_block_number});
        emit ChannelCreated(_sender_address, _receiver_address, _deposit);
    }

    /// @dev Updates internal balance Structures when the sender adds tokens to the channel.
    /// @param _sender_address The address that sends tokens.
    /// @param _receiver_address The address that receives tokens.
    /// @param _open_block_number The block number at which a channel between the
    /// sender and receiver was created.
    /// @param _added_deposit The added token deposit with which the current deposit is increased.
    function updateInternalBalanceStructs(
        address _sender_address,
        address _receiver_address,
        uint32 _open_block_number,
        uint256 _added_deposit)
        private
    {
        require(_added_deposit > 0);
        require(_open_block_number > 0);

        bytes32 key = getKey(_sender_address, _receiver_address, _open_block_number);

        require(channels[key].open_block_number > 0);
        require(closing_requests[key].settle_block_number == 0);
        require(channels[key].deposit + _added_deposit <= channel_deposit_bugbounty_limit);

        channels[key].deposit += _added_deposit;
        assert(channels[key].deposit >= _added_deposit);
        emit ChannelToppedUp(_sender_address, _receiver_address, _open_block_number, _added_deposit);
    }

    /// @dev Deletes the channel and settles by transfering the balance to the receiver
    /// and the rest of the deposit back to the sender.
    /// @param _sender_address The address that sends tokens.
    /// @param _receiver_address The address that receives tokens.
    /// @param _open_block_number The block number at which a channel between the
    /// sender and receiver was created.
    /// @param _balance The amount of tokens owed by the sender to the receiver.
    function settleChannel(
        address _sender_address,
        address _receiver_address,
        uint32 _open_block_number,
        uint256 _balance)
        private
    {
        bytes32 key = getKey(_sender_address, _receiver_address, _open_block_number);
        Channel memory channel = channels[key];

        require(channel.open_block_number > 0);
        require(_balance <= channel.deposit);
        require(withdrawn_balances[key] <= _balance);

        // Remove closed channel structures
        // channel.open_block_number will become 0
        // Change state before transfer call
        delete channels[key];
        delete closing_requests[key];

        // Send the unwithdrawn _balance to the receiver
        uint256 receiver_remaining_tokens = _balance - withdrawn_balances[key];
        _receiver_address.transfer(receiver_remaining_tokens);

        // Send deposit - balance back to sender
        _sender_address.transfer(channel.deposit - _balance);

        emit ChannelSettled(
            _sender_address,
            _receiver_address,
            _open_block_number,
            _balance,
            receiver_remaining_tokens
        );
    }

    /*
     *  Internal functions
     */

    /// @dev Internal function for getting an address from tokenFallback data bytes.
    /// @param data Bytes received.
    /// @param offset Number of bytes to offset.
    /// @return Extracted address.
    function addressFromBytes (bytes data, uint256 offset) internal pure returns (address) {
        bytes20 extracted_address;
        assembly {
            extracted_address := mload(add(data, offset))
        }
        return address(extracted_address);
    }

    /// @dev Internal function for getting the block number from tokenFallback data bytes.
    /// @param data Bytes received.
    /// @param offset Number of bytes to offset.
    /// @return Block number.
    function blockNumberFromBytes(bytes data, uint256 offset) internal pure returns (uint32) {
        bytes4 block_number;
        assembly {
            block_number := mload(add(data, offset))
        }
        return uint32(block_number);
    }

    /// @dev Check if a contract exists.
    /// @param _contract The address of the contract to check for.
    /// @return True if a contract exists, false otherwise.
    function addressHasCode(address _contract) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(_contract)
        }

        return size > 0;
    }

    function ecverify(bytes32 hash, bytes signature) internal pure returns (address signature_address) {
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))

            // Here we are loading the last 32 bytes, including 31 bytes of 's'.
            v := byte(0, mload(add(signature, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);

        signature_address = ecrecover(hash, v, r, s);

        // ecrecover returns zero on error
        require(signature_address != 0x0);

        return signature_address;
    }
}
