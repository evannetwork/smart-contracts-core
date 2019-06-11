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

import "../ds-auth/auth.sol";
import "./VerificationsRegistryLibrary.sol";


/// @title Identity Holder
/// @author evan GmbH
/// @notice can create, hold and link identities
contract IdentityHolder is DSAuth {
    event IdentityCreated(bytes32 indexed identity, address indexed owner);

    VerificationsRegistryLibrary.Identities identities;

    /// @notice create new identity
    /// @dev emits IdentityCreated event with new identity
    /// @return new identity
    function createIdentity() public returns(bytes32) {
        uint256 nonce = 0;
        bytes32 newIdentity;
        do {
          newIdentity = keccak256(abi.encodePacked(msg.sender, now, nonce++));
        } while (identities.byId[newIdentity].owner != address(0));
        identities.byId[newIdentity].owner = msg.sender;

        emit IdentityCreated(newIdentity, msg.sender);
        return newIdentity;
    }

    /// @notice change linked address/pseudonym
    /// @param _identity identity in IdentityHolder
    /// @param _link address/pseudonym will be linked to given identity
    function linkIdentity(bytes32 _identity, bytes32 _link) {
        require(identities.byId[_identity].owner == msg.sender, "sender must be owner of identity");
        identities.byId[_identity].link = _link;
    }

    /// @notice add identity, link and owner to registry, can only be done with elevated privileges
    /// @param _identity identity in IdentityHolder
    /// @param _link address/pseudonym will be linked to given identity
    /// @param _owner account that becomes owner
    function migrateIdentity(bytes32 _identity, bytes32 _link, address _owner) public auth {
        require(identities.byId[_identity].owner == address(0));
        identities.byId[_identity].link = _link;
        identities.byId[_identity].owner = _owner;
    }

    /// @notice transfer ownership of identity to another account
    /// @param _identity identity in IdentityHolder
    /// @param _newOwner account that becomes new owner
    function transferIdentity(bytes32 _identity, address _newOwner) public {
        require(identities.byId[_identity].owner == msg.sender, "sender must be owner of identity");
        identities.byId[_identity].owner = _newOwner;
    }

    /// @notice get address/pseudonym linked to given identity
    /// @param _identity identity in IdentityHolder
    /// @return linked address/pseudonym
    function getLink(bytes32 _identity) public view returns(bytes32 link) {
        return identities.byId[_identity].link;
    }

    /// @notice get owner of a given identity
    /// @param _identity identity in IdentityHolder
    /// @return owner of identity
    function getOwner(bytes32 _identity) public view returns(address owner) {
        return identities.byId[_identity].owner;
    }
}
