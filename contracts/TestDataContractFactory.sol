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

pragma solidity 0.4.24;

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
        roles.setRoleCapability(ownerRole, 0, bytes4(keccak256("moveListEntry(bytes32,uint256,bytes32[])")), true);
        roles.setRoleCapability(ownerRole, 0, bytes4(keccak256("removeListEntry(bytes32,uint256)")), true);

        // role 2 permission
        roles.setRoleCapability(memberRole, 0, bytes4(keccak256("addListEntries(bytes32[],bytes32[])")), true);
        roles.setRoleCapability(memberRole, 0, bytes4(keccak256("setEntry(bytes32,bytes32)")), true);
        roles.setRoleCapability(memberRole, 0, bytes4(keccak256("setMappingValue(bytes32,bytes32,bytes32)")), true);

        // role 2 operation permission
        // entries
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.ENTRY_LABEL(),
            keccak256(abi.encodePacked("entry_settable_by_owner")))), dc.SET_LABEL())), true);
        roles.setRoleOperationCapability(
            memberRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.ENTRY_LABEL(),
            keccak256(abi.encodePacked("entry_settable_by_member")))), dc.SET_LABEL())), true);
        // lists
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.LISTENTRY_LABEL(),
            keccak256(abi.encodePacked("list_settable_by_owner")))), dc.SET_LABEL())), true);
        roles.setRoleOperationCapability(
            memberRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.LISTENTRY_LABEL(),
            keccak256(abi.encodePacked("list_settable_by_member")))), dc.SET_LABEL())), true);
        // mappings
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.MAPPINGENTRY_LABEL(),
            keccak256(abi.encodePacked("mapping_settable_by_owner")))), dc.SET_LABEL())), true);
        roles.setRoleOperationCapability(
            memberRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.MAPPINGENTRY_LABEL(),
            keccak256(abi.encodePacked("mapping_settable_by_member")))), dc.SET_LABEL())), true);

        // owner: add, remove; member: add
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.LISTENTRY_LABEL(),
            keccak256(abi.encodePacked("list_removable_by_owner")))), dc.SET_LABEL())), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.LISTENTRY_LABEL(),
            keccak256(abi.encodePacked("list_removable_by_owner")))), dc.REMOVE_LABEL())), true);
        roles.setRoleOperationCapability(
            memberRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.LISTENTRY_LABEL(),
            keccak256(abi.encodePacked("list_removable_by_owner")))), dc.SET_LABEL())), true);

        // contract states
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.CONTRACTSTATE_LABEL(),
            BaseContractInterface.ContractState.Initial)),
            BaseContractInterface.ContractState.Draft)), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.CONTRACTSTATE_LABEL(),
            BaseContractInterface.ContractState.Draft)),
            BaseContractInterface.ContractState.PendingApproval)), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.CONTRACTSTATE_LABEL(),
            BaseContractInterface.ContractState.PendingApproval)),
            BaseContractInterface.ContractState.Draft)), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.CONTRACTSTATE_LABEL(),
            BaseContractInterface.ContractState.PendingApproval)),
            BaseContractInterface.ContractState.Approved)), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.CONTRACTSTATE_LABEL(),
            BaseContractInterface.ContractState.Approved)),
            BaseContractInterface.ContractState.Active)), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.CONTRACTSTATE_LABEL(),
            BaseContractInterface.ContractState.Approved)),
            BaseContractInterface.ContractState.Terminated)), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.CONTRACTSTATE_LABEL(),
            BaseContractInterface.ContractState.Active)),
            BaseContractInterface.ContractState.VerifyTerminated)), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.CONTRACTSTATE_LABEL(),
            BaseContractInterface.ContractState.VerifyTerminated)),
            BaseContractInterface.ContractState.Terminated)), true);
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.CONTRACTSTATE_LABEL(),
            BaseContractInterface.ContractState.VerifyTerminated)),
            BaseContractInterface.ContractState.Active)), true);

        // member states (own)
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.OWNSTATE_LABEL(),
            BaseContractInterface.ConsumerState.Initial)),
            BaseContractInterface.ConsumerState.Draft)), true);
        roles.setRoleOperationCapability(
            memberRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.OWNSTATE_LABEL(),
            BaseContractInterface.ConsumerState.Draft)),
            BaseContractInterface.ConsumerState.Rejected)), true);
        roles.setRoleOperationCapability(
            memberRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.OWNSTATE_LABEL(),
            BaseContractInterface.ConsumerState.Draft)),
            BaseContractInterface.ConsumerState.Active)), true);
        roles.setRoleOperationCapability(
            memberRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.OWNSTATE_LABEL(),
            BaseContractInterface.ConsumerState.Active)),
            BaseContractInterface.ConsumerState.Terminated)), true);

        // member states (other members)
        roles.setRoleOperationCapability(
            ownerRole, 0, keccak256(abi.encodePacked(keccak256(abi.encodePacked(
            dc.OTHERSSTATE_LABEL(),
            BaseContractInterface.ConsumerState.Draft)),
            BaseContractInterface.ConsumerState.Terminated)), true);

        return roles;
    }
}
