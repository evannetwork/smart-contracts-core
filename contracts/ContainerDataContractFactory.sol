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

        // make contract root user of own roles config
        roles.setRootUser(newContract, true);

        uint8[] memory roles1;
        assembly {
             // Create an dynamic sized array manually.
             // Don't need to define the data type here as the EVM will prefix it
             roles1 := mload(0x40) // 0x40 is the address where next free memory slot is stored in Solidity.
             mstore(add(roles1, 0x00), 9) // Set size to 14
             // omit owner roles, as initial value for field is 0 and owner role id is 0
             mstore(add(roles1, 0xc0), 1)
             mstore(add(roles1, 0xe0), 1)
             mstore(add(roles1, 0x0100), 1)
             mstore(add(roles1, 0x0120), 1)
             mstore(0x40, add(roles1, 0x0140)) // Update the msize offset to be our memory reference plus the amount of bytes we're using
        }
        bytes4[] memory sigs;
        assembly {
             // Create an dynamic sized array manually.
             // Don't need to define the data type here as the EVM will prefix it
             sigs := mload(0x40) // 0x40 is the address where next free memory slot is stored in Solidity.
             mstore(add(sigs, 0x00), 9) // Set size to 14
             mstore(add(sigs, 0x20), 0x9f99b6e7)    // init(bytes32,bool)
             mstore(add(sigs, 0x40), 0x13af4035)    // setOwner(address)
             mstore(add(sigs, 0x60), 0xb14f5d7e)    // inviteConsumer(address,address)
             mstore(add(sigs, 0x80), 0xa7b93d61)    // removeConsumer(address,address)
             mstore(add(sigs, 0xa0), 0xcf82c070)    // moveListEntry(bytes32,uint256,bytes32[])
             mstore(add(sigs, 0xc0), 0x6d948f50)    // addListEntries(bytes32[],bytes32[])
             mstore(add(sigs, 0xe0), 0xc0ff8ed5)    // removeListEntry(bytes32,uint256)
             mstore(add(sigs, 0x0100), 0x44dd44d6)  // setEntry(bytes32,bytes32)
             mstore(add(sigs, 0x0120), 0xb4f64c05)  // setMappingValue(bytes32,bytes32,bytes32)
             mstore(0x40, add(sigs, 0x0140)) // Update the msize offset to be our memory reference plus the amount of bytes we're using
        }

        roles.setRoleCapabilities(roles1, sigs, true);

        return roles;
    }
}
