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

import "./ClaimsRegistryLibrary.sol";


contract IdentityHolder {
    event IdentityCreated(bytes32 indexed identity, address indexed owner);

    ClaimsRegistryLibrary.Identities identities;

    function createIdentity() public returns(bytes32 newIdentity) {
        uint256 nonce = 0;
        bytes32 hash;
        do {
          hash = keccak256(abi.encodePacked(msg.sender, now, nonce++));
        } while (identities.byId[hash].owner != address(0));
        identities.byId[hash].owner = msg.sender;

        emit IdentityCreated(hash, msg.sender);
        return newIdentity;
    }

    function transferIdentity(bytes32 _identity, address _newOwner) public {
        require(identities.byId[_identity].owner == msg.sender, "sender must be owner of identity");
        identities.byId[_identity].owner = _newOwner;
    }
}
