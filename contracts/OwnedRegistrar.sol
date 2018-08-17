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

pragma solidity ^0.4.18;

import './ENS.sol';
import './Core.sol';

/**
 * A registrar that allocates subdomains to the first person to claim them.
 */
contract OwnedRegistrar is Owned {
    ENS ens;
    bytes32 rootNode;

    /**
     * Constructor.
     * @param ensAddr The address of the ENS registry.
     * @param node The node that this registrar administers.
     */
    function OwnedRegistrar(ENS ensAddr, bytes32 node) public {
        ens = ensAddr;
        rootNode = node;
    }

    /**
     * Register a name, or change the owner of an existing registration.
     * @param subnode The hash of the label to register.
     * @param newOwner The address of the new owner.
     */
    function register(bytes32 subnode, address newOwner) public only_owner {
        ens.setSubnodeOwner(rootNode, subnode, newOwner);
    }

    /**
     * Set the owner of the rootNode back to the owner of the registrar
     */
    function setRootNodeOwner() public only_owner {
        ens.setOwner(rootNode, owner);
    }    
}