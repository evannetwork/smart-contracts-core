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

import "./BusinessCenter.sol";
import "./DSRolesPerContract.sol";


/** @title Factory contract for creating contractus core components.*/
contract BusinessCenterFactory {
    event ContractCreated(address newAddress);

    /**@dev Creates a new business center.
     * @param rootDomain Hashed domain (e.g. namehash('contractus.eth')).
     * @return addr Address of the new business center.
     */
    function createContract(bytes32 rootDomain, address ensAddress) public returns (address addr) {
        BusinessCenter newBusinessCenter = new BusinessCenter(rootDomain, ensAddress);
        DSRolesPerContract roles = createRoles(newBusinessCenter);
        newBusinessCenter.setAuthority(roles);
        newBusinessCenter.transferOwnership(msg.sender);
        newBusinessCenter.setOwner(msg.sender);
        roles.setAuthority(roles);
        roles.setOwner(msg.sender);
        ContractCreated(newBusinessCenter);
        return newBusinessCenter;
    }

    function createRoles(address targetContract) private returns (DSRolesPerContract) {
        DSRolesPerContract roles = new DSRolesPerContract();
        address nullAddress = address(0);
        
        // roles
        uint8 ownerRole = 0;
        uint8 memberRole = 1;
        uint8 contractRole = 2;
        uint8 businessCenter = 3;
        uint8 factory = 4;

        // make contract root user of own roles config
        roles.setRootUser(targetContract, true);
        
        // user 2 role
        roles.setUserRole(msg.sender, ownerRole, true);
        roles.setUserRole(msg.sender, memberRole, true);
        roles.setUserRole(targetContract, businessCenter, true);
        
        // owner
        roles.setRoleCapability(ownerRole, nullAddress, bytes4(keccak256("getStorage()")), true);
        roles.setRoleCapability(ownerRole, nullAddress, bytes4(keccak256("init(address,uint8)")), true);
        roles.setRoleCapability(ownerRole, nullAddress, bytes4(keccak256("invite(address)")), true);
        roles.setRoleCapability(ownerRole, nullAddress, bytes4(keccak256("setJoinSchema(uint8)")), true);
        roles.setRoleCapability(ownerRole, nullAddress, bytes4(keccak256("migrateTo(address)")), true);
        roles.setRoleCapability(ownerRole, nullAddress, bytes4(keccak256("registerFactory(address)")), true);

        // members
        roles.setRoleCapability(memberRole, nullAddress, bytes4(keccak256("cancel()")), true);
        roles.setRoleCapability(memberRole, nullAddress, bytes4(keccak256("setMyProfile(bytes32)")), true);
        roles.setRoleCapability(memberRole, nullAddress, bytes4(keccak256("invite(address)")), true);

        // contracts 
        roles.setRoleCapability(contractRole, nullAddress,
            bytes4(keccak256("registerContractMember(address,address,bytes32)")), true);
        roles.setRoleCapability(contractRole, nullAddress,
            bytes4(keccak256("removeContractMember(address,address)")), true);
        roles.setRoleCapability(contractRole, nullAddress,
            bytes4(keccak256("sendContractEvent(uint256,bytes32,address)")), true);

        // businessCenter (self)
        roles.setRoleCapability(businessCenter, nullAddress,
            bytes4(keccak256("registerContractMember(address,address,bytes32)")), true);

        // factory
        roles.setRoleCapability(factory, nullAddress,
            bytes4(keccak256("registerContract(address,address,bytes32)")), true);

        return roles;
    }
}
