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
 
        return roles;
    }
}
