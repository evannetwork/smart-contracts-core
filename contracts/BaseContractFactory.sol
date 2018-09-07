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

import "./BaseContractFactoryInterface.sol";
import "./BusinessCenterInterface.sol";
import "./DSRolesPerContract.sol";


contract BaseContractFactory is BaseContractFactoryInterface {
    uint public VERSION_ID;

    event ContractCreated(bytes32 contractInfo, address newAddress);

    function createContract(address businessCenter, address provider, bytes32 contractDescription, address ensAddress)
        public returns (address);

    function createRoles(address owner) public returns (DSRolesPerContract) {
        DSRolesPerContract roles = new DSRolesPerContract();
        address nullAddress = address(0);

        // roles
        uint8 ownerRole = 0;
        uint8 memberRole = 1;
        
        // user 2 role
        roles.setUserRole(owner, ownerRole, true);
        roles.setUserRole(owner, memberRole, true);
        
        // owner
        roles.setRoleCapability(ownerRole, nullAddress, 
            bytes4(keccak256("changeContractState(uint8)")), true);
        roles.setRoleCapability(ownerRole, nullAddress,
            bytes4(keccak256("removeConsumer()")), true);

        // member           
        roles.setRoleCapability(memberRole, nullAddress, 
            bytes4(keccak256("changeConsumerState(address,uint8)")), true);

        
        return roles;
    }

    function registerContract(
            address businessCenter, address _contract, address _provider, bytes32 _contractType) public {
        if (businessCenter != 0x0) {
            BusinessCenterInterface(businessCenter).registerContract(_contract, _provider, _contractType);
        }
    }
}
