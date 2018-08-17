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

import "./BaseContractFactory.sol";
import "./DSRolesPerContract.sol";
import "./ServiceContract.sol";


contract ServiceContractFactory is BaseContractFactory {
    uint public VERSION_ID = 3;

    function createContract(address businessCenter, address provider, bytes32 contractDescription, address ensAddress) public returns (address) {
        ServiceContract newContract = new ServiceContract(provider, keccak256("ServiceContract"), contractDescription, ensAddress);
        DSRolesPerContract roles = createRoles(provider);
        newContract.setAuthority(roles);
        bytes32 contractType = newContract.contractType();
        super.registerContract(businessCenter, newContract, provider, contractType);
        newContract.setOwner(provider);
        roles.setOwner(newContract);
        ContractCreated(keccak256("ServiceContract"), newContract);
        return newContract;
    }

    function createRoles(address owner) public returns (DSRolesPerContract) {
        DSRolesPerContract roles = super.createRoles(owner);
        // roles
        uint8 memberRole = 1;

        // role 2 permission
        // owner
        roles.setRoleCapability(memberRole, msg.sender,
            bytes4(keccak256("addService(address,string,string,string)")), true);
        // members do not have explicit role permissions, so these actions are public
        roles.setPublicCapability(0, bytes4(keccak256("sendAnswer(bytes32,uint256)")), true);
        roles.setPublicCapability(0, bytes4(keccak256("sendCall(bytes32,bytes32)")), true);
        roles.setPublicCapability(0, bytes4(keccak256("setMultiSharing(bytes32,bytes32)")), true);

        return roles;
    }
}
