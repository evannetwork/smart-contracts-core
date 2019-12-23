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

import "../Core.sol";
import "../EnsReader.sol";


/// @title Registry for VC documents
/// @author evan GmbH
contract VcRegistry is Owned, EnsReader {
    event VcIdRegistered(bytes32 indexed vcId, address indexed owner);

    mapping(bytes32 => address) public vcOwner;
    mapping(bytes32 => bytes32) public vcStore;
    mapping(bytes32 => bool)    public vcRevoke;

    /// @notice create new id
    /// @return new identity
    function createId() public returns(bytes32) {
        uint256 nonce = 0;
        bytes32 newId;
        do {
          newId = keccak256(abi.encodePacked(msg.sender, now, nonce++));
        } while (vcOwner[newId] != address(0));
        vcOwner[newId] = msg.sender;

        emit VcIdRegistered(newId, msg.sender);
        return newId;
    }

    /// @notice set value ENS registry
    /// @param ensAddress address of ENS registry
    function setEnsRegistry(address ensAddress) public only_owner {
        super.setEns(ensAddress);
    }

    /// @notice set VC for a VC ID
    /// @param vcId Hashed ID of the VC
    /// @param value The VC document to be stored
    function setVc(bytes32 vcId, bytes32 value) public {
      require(msg.sender == vcOwner[vcId],
        'Not allowed to write VC');

      vcStore[vcId] = value;
    }

    /// @notice revoke VC for VC ID
    /// @param vcId Hashed ID of the VC ID
    function revokeVC(bytes32 vcId) public {
      require(msg.sender == vcOwner[vcId]);
        vcRevoke[vcId] = True;
    }
}
