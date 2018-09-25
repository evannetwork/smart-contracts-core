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

pragma solidity 0.4.20;

import "./BaseContractInterface.sol";
import "./BusinessCenterInterface.sol";
import "./DataStoreIndex.sol";
import "./EnsReader.sol";
import "./EventHubBusinessCenter.sol";
import "./DSRolesPerContract.sol";
import "./ds-auth/auth.sol";


contract BusinessCenter is BusinessCenterInterface, EnsReader, DSAuth {
    bytes32 constant private CONTRACT_AVAILABLE_LABEL =
        0x40e1b59951174098af452e0cb539d0ad570971d67c8ff9b10c1bc581a1e693f3; //web3.keccak256('contractAvailable')

    bytes32 constant private CONTRACT_LABEL =
        0x7f6dd79f0020bee2024a097aaa5d32ab7ca31126fa375538de047e7475fa8572; //web3.keccak256('contract')

    bytes32 constant private EVENTHUB_LABEL =
        0xea14ea6d138254c1a2931c6a19f6888c7b52f512d165cfa428183a53dd9dfb8c; //web3.keccak256('eventhub')

    bytes32 constant private MEMBER_LABEL =
        0x14ceb1149cdab84b395151a21d3de6707dd76fff3e7bc4e018925a9986b7f72f; //web3.keccak256('member')

    bytes32 constant private MEMBER_SINCE_LABEL =
        0x0243ce6f697bb3c4824af489e2da64a35e3161d6d90ed864e08857ee0edcf284; //web3.keccak256('memberSince')

    uint8 constant private OWNER_ROLE = 0;
    uint8 constant private MEMBER_ROLE = 1;
    uint8 constant private CONTRACT_ROLE = 2;
    uint8 constant private FACTORY_ROLE = 4;
    mapping(address => bytes32) private profiles;
    bytes32 public rootDomain;
    DataStoreIndex public db;

    function BusinessCenter(bytes32 domain, address ensAddress) public {
        VERSION_ID = 2;
        rootDomain = domain;
        setEns(ensAddress);
    }

    function init(DataStoreIndex oldDb, JoinSchema _joinSchema) public auth {
        if (address(oldDb) != 0x0) {
            db = oldDb;
        } else {
            DataStoreMap data = new DataStoreMap();
            db = new DataStoreIndex(data);
            data.transferOwnership(db);
        }
        joinSchema = _joinSchema;
    }

    function join() public {
        if (DSRolesPerContract(authority).hasUserRole(msg.sender, OWNER_ROLE)) {
            addMember(msg.sender);
        } else if (joinSchema == JoinSchema.SelfJoin || joinSchema == JoinSchema.JoinOrAdd) {
            addMember(msg.sender);
        } else if (joinSchema == JoinSchema.Handshake) {
            if (pendingInvites[msg.sender]) {
                pendingInvites[msg.sender] = false;
                addMember(msg.sender);
            } else {
                pendingJoins[msg.sender] = true;
                getEventHub().sendMemberEvent(
                    uint(EventHubBusinessCenter.BusinessCenterEventType.PendingJoin), msg.sender);
            }
        } else {
            assert(false);  // throw
        }
    }

    function invite(address newMember) public auth {
        if (joinSchema == JoinSchema.AddOnly) {
            addMember(newMember);
        } else if (joinSchema == JoinSchema.Handshake) {
            if (pendingJoins[newMember]) {
                pendingJoins[newMember] = false;
                addMember(newMember);
            } else {
                pendingInvites[newMember] = true;
                getEventHub().sendMemberEvent(
                    uint(EventHubBusinessCenter.BusinessCenterEventType.PendingInvite), newMember);
            }
        } else if (joinSchema == JoinSchema.JoinOrAdd) {
            addMember(newMember);
        } else {
            assert(false);  // throw
        }
    }

    function cancel() public auth {
        var (memberIndex, okay) = db.listIndexOf(MEMBER_LABEL, keccak256(bytes32(msg.sender)));
        assert(okay);        
        db.listEntryRemove(MEMBER_LABEL, memberIndex);
        setMyProfile(bytes32(0));

        // update permissions
        DSRolesPerContract roles = DSRolesPerContract(authority);
        roles.setUserRole(msg.sender, MEMBER_ROLE, false);

        getEventHub().sendMemberEvent(uint(EventHubBusinessCenter.BusinessCenterEventType.Cancel), msg.sender);
    }

    // used when creating the contract, registers creator as first member
    function registerContract(address _contract, address _provider, bytes32 _contractType) public auth {
        db.listEntryAdd(CONTRACT_LABEL, bytes32(_contract));
        db.listEntryAdd(CONTRACT_AVAILABLE_LABEL, bytes32(_contract));
        DSRolesPerContract roles = DSRolesPerContract(authority);
        // add current contract as contract role
        roles.setUserRole(_contract, CONTRACT_ROLE, true);
        registerContractMember(_contract, _provider, _contractType);
    }

    // used when inviting new members or when a new contract is created
    function registerContractMember(address _contract, address _member, bytes32 _contractType) public auth {
        // set address in members index
        bytes32 label = keccak256(MEMBER_LABEL, keccak256(bytes32(_member)));
        DataStoreIndex userIndex = DataStoreIndex(db.indexGet(label));
        db.indexMakeModerator(label);
        userIndex.listEntryAdd(_contractType, bytes32(_contract));
        userIndex.removeModeratorship();

        // notify about new members
        getEventHub().sendContractEvent(
            uint(EventHubBusinessCenter.BusinessCenterEventType.New), _contractType, _contract, _member);
    }

    // will be called from a base contract
    function removeContractMember(address _contract, address _member) public auth {
        assert(isMember(_member) && isContract(_contract));

        BaseContractInterface contractInterface = BaseContractInterface(_contract);
        bytes32 contractTypeLabel = contractInterface.contractType();
        var (index, okay) = userIndex.listIndexOf(contractTypeLabel, bytes32(_contract));
        assert(okay);

        bytes32 label = keccak256(MEMBER_LABEL, keccak256(bytes32(_member)));
        DataStoreIndex userIndex = DataStoreIndex(db.indexGet(label));
        db.indexMakeModerator(label);
        userIndex.listEntryRemove(contractInterface.contractType(), index);
        userIndex.removeModeratorship();
    }

    function migrateTo(address newBc) public auth {
        db.transferOwnership(newBc);
    }

    function sendContractEvent(uint eventType, bytes32 contractType, address member) public auth {
        getEventHub().sendContractEvent(eventType, contractType, msg.sender, member);
    }

    function registerFactory(address factoryId) public auth {
        DSRolesPerContract(authority).setUserRole(factoryId, FACTORY_ROLE, true);
    }

    function setMyProfile(bytes32 profile) public auth {
        profiles[msg.sender] = profile;
    }

    function setJoinSchema(JoinSchema _joinSchema) public auth {
        joinSchema = _joinSchema;
    }

    function getMyIndex() public constant returns (DataStoreIndex) {
        bytes32 keyForMemberIndex = keccak256(MEMBER_LABEL, keccak256(bytes32(msg.sender)));
        return DataStoreIndex(db.indexGet(keyForMemberIndex));
    }

    function getProfile(address account) public constant returns (bytes32) {
        return profiles[account];
    }

    function getStorage() public auth constant returns (DataStoreIndex) {
        return db;
    }

    // check if an address is a member
    function isMember(address _member) public constant returns (bool) {
        var (, memberOkay) = db.listIndexOf(MEMBER_LABEL, keccak256(bytes32(_member)));
        return memberOkay;
    }

    // check if an address is a contract
    function isContract(address _contract) public constant returns (bool) {
        var (, contractOkay) = db.listIndexOf(CONTRACT_LABEL, bytes32(_contract));
        return contractOkay;
    }

    function addMember(address newMember) private {
        assert(!isMember(newMember));
        db.listEntryAdd(MEMBER_LABEL, keccak256(bytes32(newMember)));

        bytes32 keyForMemberIndex = keccak256(MEMBER_LABEL, keccak256(bytes32(newMember)));

        // create user index for own db
        DataStoreIndex localUserIndex;
        address localUserIndexAddress = DataStoreIndex(db.indexGet(keyForMemberIndex));
        if (localUserIndexAddress != 0x0) {
            db.indexMakeModerator(keyForMemberIndex);
            localUserIndex = DataStoreIndex(localUserIndexAddress);
        } else {
            DataStoreMap localUserData = new DataStoreMap();
            localUserIndex = new DataStoreIndex(localUserData);
            localUserData.transferOwnership(localUserIndex);
            // store user index in own db
            db.containerSet(keyForMemberIndex, bytes32(address(localUserIndex)));
        }
        // track joined date
        localUserIndex.containerSet(MEMBER_SINCE_LABEL, bytes32(now));
        // remove moderatorship or assign index contract to local storage
        if (localUserIndexAddress != 0x0) {
            localUserIndex.removeModeratorship();
        } else {
            localUserIndex.transferOwnership(db);
        }

        // update permissions
        DSRolesPerContract roles = DSRolesPerContract(authority);
        roles.setUserRole(newMember, MEMBER_ROLE, true);

        getEventHub().sendMemberEvent(uint(EventHubBusinessCenter.BusinessCenterEventType.New), msg.sender);
    }

    function getEventHub() private constant returns(EventHubBusinessCenter) {
        return EventHubBusinessCenter(getAddr(EVENTHUB_LABEL));
    }

    function getMembersAddressIndex(address member) private constant returns(DataStoreIndex) {
        return DataStoreIndex(address(db.containerGet(keccak256(MEMBER_LABEL, bytes32(member)))));
    }
}
