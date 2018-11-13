/*
  Copyright (c) 2018-present evan GmbH.
 
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
 
      http://www.apache.org/licenses/LICENSE-2.0
 
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  
*/

pragma solidity ^0.4.24;
import "./BaseContract.sol";
import "./DataContractInterface.sol";
import "./DSRolesPerContract.sol";


/// @title contract for generic data storage, that can handle lists and entries
/// @author contractus GmbH
/// @notice this is a contract with abstract functions that is used as an interface for DataContracts
/// @dev requires calling "init" before usage
contract DataContract is DataContractInterface, BaseContract {
    //// labels for buildig keccak256 keys
    // web3.utils.soliditySha3('subcontracts')
    bytes32 public constant SUBCONTRACTS_LABEL = 0x33baa6f316fab89cb11f57cf36f92fc446eeabbee455d30c346989e18dba49c4;
    // web3.utils.soliditySha3('entry')
    bytes32 public constant ENTRY_LABEL = 0x84f3db82fb6cd291ed32c6f64f7f5eda656bda516d17c6bc146631a1f05a1833;
    // web3.utils.soliditySha3('listentry')
    bytes32 public constant LISTENTRY_LABEL = 0x7da2a80303fd8a8b312bb0f3403e22702ece25aa85a5e213371a770a74a50106; 
    // web3.utils.soliditySha3('mappingentry')
    bytes32 public constant MAPPINGENTRY_LABEL = 0xd9234c2c276ff426c50a259dd40abb4cdd9767973f4a72f6e032e829f681e0b4;
    // web3.utils.soliditySha3('contractstate')
    bytes32 public constant CONTRACTSTATE_LABEL = 0xf0af2cee3e7130dfb5ef02ebfaf64a30da17e9c9c26d3d40ece69a2e0ee1d69e;
    // web3.utils.soliditySha3('ownstate')
    bytes32 public constant OWNSTATE_LABEL = 0x56ead3438bd16b0aaea9b0b78119b1db8a5382b496db7a1989fe7a32f9890f7c;
    // web3.utils.soliditySha3('othersstate')
    bytes32 public constant OTHERSSTATE_LABEL = 0xa287c88bf56474b8c2de2568111316e26d1b3572718b1a8cdf0c881a767e4cb7;
    // web3.utils.soliditySha3('count')
    bytes32 public constant COUNT_LABEL = 0xc82306b6ab1b4c67429442feb1e6d238135a6cfcaa471a01b0e336f01b048e38;
    // web3.utils.soliditySha3('set')
    bytes32 public constant SET_LABEL = 0xd2f67e6aeaad1ab7487a680eb9d3363a597afa7a3de33fa9bf3ae6edcb88435d;
    // web3.utils.soliditySha3('remove')
    bytes32 public constant REMOVE_LABEL = 0x8dd27a19ebb249760a6490a8d33442a54b5c3c8504068964b74388bfe83458be; 

    // data storage
    mapping (bytes32 => bytes32) public hashMapping;

    // use null address to ignore code parameter but keep functions interface conform
    address public nullAddress = 0;

    /// @notice create new DataContract instance
    /// @dev requires calling "init" before usage
    /// @param _provider future owner of the contract
    /// @param _contractType bytes32 representation of the contracts type
    /// @param _contractDescription DBCP definition of the contract
    /// @param _ensAddress address of the ENS contract
    constructor(
        address _provider,
        bytes32 _contractType,
        bytes32 _contractDescription,
        address _ensAddress) public BaseContract(_provider, _contractType, _contractDescription, _ensAddress) {
        contractState = ContractState.Draft;
        created = now;
    }

    /// @notice add entries to a list
    /// @dev keep in mind that list do not provide a fixed order;
    /// they can be iterated, but deleting entries repositions items
    /// @param keys keccak256 hashes of the list names
    /// @param values values to add to this list
    function addListEntries(bytes32[] keys, bytes32[] values) public auth {
        for (uint256 i = 0; i < keys.length; i++) {
            // create key for list ('$KEY.listentry')
            bytes32 listKey = keccak256(abi.encodePacked(LISTENTRY_LABEL, keys[i]));
            DSRolesPerContract roles = DSRolesPerContract(authority);
            // check permission ('set.$KEY.listentry')
            assert(roles.canCallOperation(msg.sender, nullAddress, keccak256(abi.encodePacked(listKey, SET_LABEL))));
            // get count ('listcount.$KEY.listentry')
            bytes32 listCountKey = keccak256(abi.encodePacked(listKey, COUNT_LABEL));
            uint256 listEntryCount = uint256(hashMapping[listCountKey]);
            uint256 index;
            for (uint256 j = 0; j < values.length; j++) {
                // set entry ('$INDEX.$KEY.listentry')
                index = listEntryCount++;
                hashMapping[keccak256(abi.encodePacked(listKey, index))] = values[j];
            }
            // update count
            hashMapping[listCountKey] = bytes32(listEntryCount);
        }
    }

    /// @notice set the state of a consumer in the contract
    /// @dev shadows implementation of BaseContractInterface;
    /// can only follow state transitions defined in authority
    /// @param targetMember set state for this member
    /// @param newState state to set
    function changeConsumerState(address targetMember, ConsumerState newState) public {
        DSRolesPerContract roles = DSRolesPerContract(authority);
        if (msg.sender == targetMember) {
            assert(roles.canCallOperation(msg.sender, nullAddress,
                keccak256(abi.encodePacked(keccak256(abi.encodePacked(OWNSTATE_LABEL, consumerState[targetMember])), newState))));
        } else {
            assert(roles.canCallOperation(msg.sender, nullAddress,
                keccak256(abi.encodePacked(keccak256(abi.encodePacked(OTHERSSTATE_LABEL, consumerState[targetMember])), newState))));
        }
        super.changeConsumerState(targetMember, newState);
    }

    /// @notice update contract state
    /// @dev shadows implementation of BaseContractInterface;
    /// can only follow state transitions defined in authority
    /// @param newState state to set
    function changeContractState(ContractState newState) public {
        DSRolesPerContract roles = DSRolesPerContract(authority);
        assert(roles.canCallOperation(msg.sender, nullAddress,
            keccak256(abi.encodePacked(keccak256(abi.encodePacked(CONTRACTSTATE_LABEL, contractState)), newState))));
        super.changeContractState(newState);
    }

    /// @notice setup basic contract structure; must be called before using this contract
    /// @param domain contractus root domain; is used for event hub lookups
    /// @param allowConsumerInviteIn allow other consumers to invite contract participants
    function init(bytes32 domain, bool allowConsumerInviteIn) public auth {
        rootDomain = domain;
        allowConsumerInvite = allowConsumerInviteIn;
    }

    /// @notice move a list entry from a list into one or multiple lists
    /// @param key keccak256 hash of the list name
    /// @param index index of the element to delete
    /// @param keys keccak256 hashes of the list names
    function moveListEntry(bytes32 key, uint256 index, bytes32[] keys) public auth {
        bytes32[] memory values = new bytes32[](1);
        values[0] = getListEntry(key, index);
        removeListEntry(key, index);
        addListEntries(keys, values);
    }

    /// @notice remove a list entry from a list
    /// @dev moves last element from list into the slot where the deleted entry was placed
    /// @param key keccak256 hash of the list name
    /// @param index index of the element to delete
    function removeListEntry(bytes32 key, uint256 index) public auth {
        // create key for list ('$KEY.listentry')
        bytes32 listKey = keccak256(abi.encodePacked(LISTENTRY_LABEL, key));
        DSRolesPerContract roles = DSRolesPerContract(authority);
        // check permission
        assert(roles.canCallOperation(msg.sender, nullAddress, keccak256(abi.encodePacked(listKey, REMOVE_LABEL))));
        // get count ('listcount.$KEY.listentry')
        bytes32 listCountKey = keccak256(abi.encodePacked(listKey, COUNT_LABEL));
        uint256 listEntryCount = uint256(hashMapping[listCountKey]);
        assert(index < listEntryCount);
        uint256 lastIndex = listEntryCount - 1;
        hashMapping[listCountKey] = bytes32(lastIndex);
        if (lastIndex != 0) {
            hashMapping[keccak256(abi.encodePacked(listKey, index))] = hashMapping[keccak256(abi.encodePacked(listKey, lastIndex))];
        }
        delete hashMapping[keccak256(abi.encodePacked(listKey, lastIndex))];
    }

    /// @notice set a value of an entry in the contract
    /// @param key keccak256 hash of a key
    /// @param value value to set for this key
    function setEntry(bytes32 key, bytes32 value) public auth {
        // create key for entry
        bytes32 entryKey = keccak256(abi.encodePacked(ENTRY_LABEL, key));
        DSRolesPerContract roles = DSRolesPerContract(authority);
        // check permission
        assert(roles.canCallOperation(msg.sender, nullAddress, keccak256(abi.encodePacked(entryKey, SET_LABEL))));
        // set entry
        hashMapping[entryKey] = value;
    }

    /// @notice set a value of a mapping property in the contract
    /// @param mappingHash keccak256 hash of the mapping name
    /// @param key keccak256 hash of the mappings entry/property name
    /// @param value value to set for this key
    function setMappingValue(bytes32 mappingHash, bytes32 key, bytes32 value) public auth {
        // create key for mapping ('$KEY.listentry')
        bytes32 mappingKey = keccak256(abi.encodePacked(MAPPINGENTRY_LABEL, mappingHash));
        DSRolesPerContract roles = DSRolesPerContract(authority);
        // check permission ('set.$KEY.listentry')
        assert(roles.canCallOperation(msg.sender, nullAddress, keccak256(abi.encodePacked(mappingKey, SET_LABEL))));

        // set value
        hashMapping[keccak256(abi.encodePacked(mappingKey, key))] = value;
    }

    /// @notice retrieve entry value for a key
    /// @param key keccak256 hash of a key
    /// @return value for this key
    function getEntry(bytes32 key) public constant returns(bytes32) {
        // return entry
        return hashMapping[keccak256(abi.encodePacked(ENTRY_LABEL, key))];
    }

    /// @notice get number of elements in a list
    /// @param key keccak256 hash of the list name
    /// @return number of elements
    function getListEntryCount(bytes32 key) public constant returns(uint256) {
        // return entry ('listcount.$KEY.listentry')
        return uint256(hashMapping[keccak256(abi.encodePacked(keccak256(abi.encodePacked(LISTENTRY_LABEL, key)), COUNT_LABEL))]);
    }

    /// @notice retrieve a single entry from a list
    /// @param key keccak256 hash of the list name
    /// @param index index of the element to retrieve
    /// @return value for this list entry
    function getListEntry(bytes32 key, uint256 index) public constant returns(bytes32) {
        // return entry ('$INDEX.$KEY.listentry')
        return hashMapping[keccak256(abi.encodePacked(keccak256(abi.encodePacked(LISTENTRY_LABEL, key)), index))];
    }

    /// @notice retrieve a single entry from a mapping
    /// @param mappingHash keccak256 hash of the mapping name
    /// @param key keccak256 hash of the mappings entry/property name
    /// @return value for this mapping entry
    function getMappingValue(bytes32 mappingHash, bytes32 key) public constant returns(bytes32) {
        // return entry ('$KEY.$MAPPING.listentry')
        return hashMapping[keccak256(abi.encodePacked(keccak256(abi.encodePacked(MAPPINGENTRY_LABEL, mappingHash)), key))];
    }
}
