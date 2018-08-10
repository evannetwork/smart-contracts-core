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

pragma solidity ^0.4.15;

import "./DSRolesPerContract.sol";
import "./MultiSigWallet.sol";


contract MultiSigWalletFactory {
    uint public VERSION_ID = 1;

    event ContractCreated(bytes32 contractInfo, address newAddress);

    function createContract(address manager, address[] _owners, uint _required) public returns(address) {
        // create contract and roles
        MultiSigWallet newContract = new MultiSigWallet(_owners, _required);
        DSRolesPerContract roles = new DSRolesPerContract();

        // register current user as wallets root user
        roles.setRootUser(manager, true);

        // configure auth relations
        newContract.setAuthority(roles);
        roles.setAuthority(roles);
        roles.setOwner(manager);

        // wrap up creation
        ContractCreated(keccak256("MultiSigWallet"), newContract);
        return newContract;
    }
}