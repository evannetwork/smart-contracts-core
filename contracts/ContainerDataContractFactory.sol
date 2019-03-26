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
 

contract ContainerDataContractFactory is BaseContractFactory {
    uint public constant VERSION_ID = 1;
 
    function createContract(address businessCenter, address provider, bytes32 _contractDescription, address ensAddress
            ) public returns (address) {
        DataContract newContract = new DataContract(provider, keccak256("ContainerDataContractFactory"), _contractDescription, ensAddress);
        DSRolesPerContract roles = createRoles(provider, newContract);
        newContract.setAuthority(roles);
        bytes32 contractType = newContract.contractType();
        super.registerContract(businessCenter, newContract, provider, contractType);
        newContract.setOwner(provider);
        roles.setAuthority(roles);
        roles.setOwner(provider);
        emit ContractCreated(keccak256("ContainerDataContractFactory"), newContract);
        return newContract;
    }
 
    function createRoles(address owner, address newContract) public returns (DSRolesPerContract) {
        DSRolesPerContract roles = super.createRoles(owner);
        // roles
        uint8 ownerRole = 0;
        uint8 memberRole = 1;
 
        // make contract root user of own roles config
        roles.setRootUser(newContract, true);
 
        // role 2 permission (contract owner)
        roles.setRoleCapability(ownerRole, 0, 0x9f99b6e7, true);    // init(bytes32,bool)
        roles.setRoleCapability(ownerRole, 0, 0x13af4035, true);    // setOwner(address)
        roles.setRoleCapability(ownerRole, 0, 0xb14f5d7e, true);    // inviteConsumer(address,address)
        roles.setRoleCapability(ownerRole, 0, 0xa7b93d61, true);    // removeConsumer(address,address)
        roles.setRoleCapability(ownerRole, 0, 0xcf82c070, true);    // moveListEntry(bytes32,uint256,bytes32[])
 
        // role 2 permission (members)
        roles.setRoleCapability(memberRole, 0, 0x6d948f50, true);   // addListEntries(bytes32[],bytes32[])
        roles.setRoleCapability(memberRole, 0, 0xc0ff8ed5, true);   // removeListEntry(bytes32,uint256)
        roles.setRoleCapability(memberRole, 0, 0x44dd44d6, true);   // setEntry(bytes32,bytes32)
        roles.setRoleCapability(memberRole, 0, 0xb4f64c05, true);   // setMappingValue(bytes32,bytes32,bytes32)
 
        // contract states
        bytes32 contractStateLabel = 0xf0af2cee3e7130dfb5ef02ebfaf64a30da17e9c9c26d3d40ece69a2e0ee1d69e;
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
        bytes32 ownstateLabel = 0x56ead3438bd16b0aaea9b0b78119b1db8a5382b496db7a1989fe7a32f9890f7c;
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
            0xa287c88bf56474b8c2de2568111316e26d1b3572718b1a8cdf0c881a767e4cb7,
            BaseContractInterface.ConsumerState.Draft,
            BaseContractInterface.ConsumerState.Terminated), true);

        return roles;
    }
 
    function hashConsumerStateChange(bytes32 label, BaseContractInterface.ConsumerState from, BaseContractInterface.ConsumerState to) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(keccak256(abi.encodePacked(label, from)), to));
    }
 
    function hashContractStateChange(bytes32 label, BaseContractInterface.ContractState from, BaseContractInterface.ContractState to) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(keccak256(abi.encodePacked(label, from)), to));
    }
}
