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

import "./DSRolesPerContract.sol";
import "./DigitalTwin.sol";


contract DigitalTwinFactory {
    event ContractCreated(bytes32 contractInfo, address newAddress);

    uint public constant VERSION_ID = 1;

    /// @notice create new digital twin contract instance
    function createContract(address provider) public returns (address) {
        DigitalTwin newContract = new DigitalTwin();
        DSRolesPerContract roles = createRoles(provider, newContract);
        newContract.setAuthority(roles);
        newContract.setOwner(provider);
        roles.setAuthority(roles);
        roles.setOwner(provider);
        emit ContractCreated(keccak256("DigitalTwin"), newContract);
        return newContract;
    }

    function createRoles(address owner, DigitalTwin newContract) private returns (DSRolesPerContract) {
        DSRolesPerContract roles = new DSRolesPerContract();
        address nullAddress = address(0);

        uint8 ownerRole = 0;
        uint8 memberRole = 1;
        
        // user 2 role
        roles.setUserRole(owner, ownerRole, true);
        roles.setUserRole(owner, memberRole, true);

        // make contract root user of own roles config
        roles.setRootUser(newContract, true);

        return roles;
    }
}
