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

import "./BaseContractFactory.sol";
import "./BaseContractInterface.sol";
import "./DSRolesPerContract.sol";
import "./DataContract.sol";


contract TestDataContractFactory is BaseContractFactory {
    uint public constant VERSION_ID = 3;

    function createContract(address businessCenter, address provider, bytes32 _contractDescription, address ensAddress
            ) public returns (address) {
        DataContract newContract = new DataContract(provider, keccak256("TestDataContract"), _contractDescription, ensAddress);
        DSRolesPerContract roles = createRoles(provider, newContract);
        newContract.setAuthority(roles);
        bytes32 contractType = newContract.contractType();
        super.registerContract(businessCenter, newContract, provider, contractType);
        newContract.setOwner(provider);
        roles.setAuthority(roles);
        roles.setOwner(provider);
        emit ContractCreated(keccak256("TestDataContract"), newContract);
        return newContract;
    }

    function createRoles(address owner, address newContract) public returns (DSRolesPerContract) {
        DSRolesPerContract roles = super.createRoles(owner);
        DataContract dc = DataContract(newContract);
        // roles
        uint8 ownerRole = 0;
        uint8 memberRole = 1;

        // make contract root user of own roles config
        roles.setRootUser(newContract, true);

        // role 2 permission
        roles.setRoleCapability(ownerRole, 0, bytes4(keccak256("init(bytes32,bool)")), true);
        roles.setRoleCapability(ownerRole, 0, bytes4(keccak256("setOwner(address)")), true);
        roles.setRoleCapability(ownerRole, 0, bytes4(keccak256("removeConsumer(address,address)")), true);
        roles.setRoleCapability(ownerRole, 0, bytes4(keccak256("moveListEntry(bytes32,uint256,bytes32[])")), true);
        roles.setRoleCapability(ownerRole, 0, bytes4(keccak256("removeListEntry(bytes32,uint256)")), true);

        // role 2 permission
        roles.setRoleCapability(memberRole, 0, bytes4(keccak256("addListEntries(bytes32[],bytes32[])")), true);
        roles.setRoleCapability(memberRole, 0, bytes4(keccak256("setEntry(bytes32,bytes32)")), true);
        roles.setRoleCapability(memberRole, 0, bytes4(keccak256("setMappingValue(bytes32,bytes32,bytes32)")), true);

        // role 2 operation permission
        bytes32 setLabel = dc.SET_LABEL();
        bytes32 entryLabel = dc.ENTRY_LABEL();
        bytes32 listentryLabel = dc.LISTENTRY_LABEL();
        bytes32 mappingentryLabel = dc.MAPPINGENTRY_LABEL();
        // entries
        roles.setRoleOperationCapability(ownerRole, 0, hashPropertyCapability(entryLabel, "entry_settable_by_owner", setLabel), true);
        roles.setRoleOperationCapability(memberRole, 0, hashPropertyCapability(entryLabel, "entry_settable_by_member", setLabel), true);
        // lists
        roles.setRoleOperationCapability(ownerRole, 0, hashPropertyCapability(listentryLabel, "list_settable_by_owner", setLabel), true);
        roles.setRoleOperationCapability(memberRole, 0, hashPropertyCapability(listentryLabel, "list_settable_by_member", setLabel), true);
        // mappings
        roles.setRoleOperationCapability(ownerRole, 0, hashPropertyCapability(mappingentryLabel, "mapping_settable_by_owner", setLabel), true);
        roles.setRoleOperationCapability(memberRole, 0, hashPropertyCapability(mappingentryLabel, "mapping_settable_by_member", setLabel), true);

        // owner: add, remove; member: add
        roles.setRoleOperationCapability(ownerRole, 0, hashPropertyCapability(listentryLabel, "list_removable_by_owner", setLabel), true);
        roles.setRoleOperationCapability(ownerRole, 0, hashPropertyCapability(listentryLabel, "list_removable_by_owner", dc.REMOVE_LABEL()), true);
        roles.setRoleOperationCapability(memberRole, 0, hashPropertyCapability(listentryLabel, "list_removable_by_owner", setLabel), true);

        // contract states
        bytes32 contractStateLabel = dc.CONTRACTSTATE_LABEL();
        roles.setRoleOperationCapability(
            ownerRole, 0, hashContractStateChange(
            contractStateLabel,
            BaseContractInterface.ContractState.Initial,
            BaseContractInterface.ContractState.Draft), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, hashContractStateChange(
            contractStateLabel,
            BaseContractInterface.ContractState.Draft,
            BaseContractInterface.ContractState.PendingApproval), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, hashContractStateChange(
            contractStateLabel,
            BaseContractInterface.ContractState.PendingApproval,
            BaseContractInterface.ContractState.Draft), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, hashContractStateChange(
            contractStateLabel,
            BaseContractInterface.ContractState.PendingApproval,
            BaseContractInterface.ContractState.Approved), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, hashContractStateChange(
            contractStateLabel,
            BaseContractInterface.ContractState.Approved,
            BaseContractInterface.ContractState.Active), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, hashContractStateChange(
            contractStateLabel,
            BaseContractInterface.ContractState.Approved,
            BaseContractInterface.ContractState.Terminated), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, hashContractStateChange(
            contractStateLabel,
            BaseContractInterface.ContractState.Active,
            BaseContractInterface.ContractState.VerifyTerminated), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, hashContractStateChange(
            contractStateLabel,
            BaseContractInterface.ContractState.VerifyTerminated,
            BaseContractInterface.ContractState.Terminated), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, hashContractStateChange(
            contractStateLabel,
            BaseContractInterface.ContractState.VerifyTerminated,
            BaseContractInterface.ContractState.Active), true);

        // member states (own)
        bytes32 ownstateLabel = dc.OWNSTATE_LABEL();
        roles.setRoleOperationCapability(
            ownerRole, 0, hashConsumerStateChange(
            ownstateLabel,
            BaseContractInterface.ConsumerState.Initial,
            BaseContractInterface.ConsumerState.Draft), true);
        roles.setRoleOperationCapability(
            memberRole, 0, hashConsumerStateChange(
            ownstateLabel,
            BaseContractInterface.ConsumerState.Draft,
            BaseContractInterface.ConsumerState.Rejected), true);
        roles.setRoleOperationCapability(
            memberRole, 0, hashConsumerStateChange(
            ownstateLabel,
            BaseContractInterface.ConsumerState.Draft,
            BaseContractInterface.ConsumerState.Active), true);
        roles.setRoleOperationCapability(
            memberRole, 0, hashConsumerStateChange(
            ownstateLabel,
            BaseContractInterface.ConsumerState.Active,
            BaseContractInterface.ConsumerState.Terminated), true);

        // member states (other members)
        roles.setRoleOperationCapability(
            ownerRole, 0, hashConsumerStateChange(
            dc.OTHERSSTATE_LABEL(),
            BaseContractInterface.ConsumerState.Draft,
            BaseContractInterface.ConsumerState.Terminated), true);

        return roles;
    }


    function hashPropertyCapability(bytes32 label, string name, bytes32 operation) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(keccak256(abi.encodePacked(label, keccak256(abi.encodePacked(name)))), operation));
    }

    function hashContractStateChange(bytes32 label, BaseContractInterface.ContractState from, BaseContractInterface.ContractState to) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(keccak256(abi.encodePacked(label, from)), to));
    }

    function hashConsumerStateChange(bytes32 label, BaseContractInterface.ConsumerState from, BaseContractInterface.ConsumerState to) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(keccak256(abi.encodePacked(label, from)), to));
    }
}
