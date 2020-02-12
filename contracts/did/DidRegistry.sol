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
import "../verifications/IdentityHolder.sol";


/// @title Registry for DID documents
/// @author evan GmbH
contract DidRegistry is Owned, EnsReader {
    // sha3('contractidentities')
    bytes32 public contractRegistryNode = 0xaca561d654b9355e105c347c1b404d12052bd568ed9c53ede94e3e2a3123cc3c;
    mapping(bytes32 => bytes32) public didDocuments;
    mapping(bytes32 => bool) public deactivatedDids;
    bytes32[] public registeredHashes;

    /// @notice set DID document for a DID hash
    /// @param targetHash hash identity reference to set DID document hash for
    /// @param value of DID document
    function setDidDocument(bytes32 targetHash, bytes32 value) public {
        require(
            // allow if owner of registry, required for migration scenarios
            msg.sender == owner ||
            // allow if msg.sender === targetHash --> set own hash (called from identity)
            bytes32(msg.sender) == targetHash ||
            // allow if msg.sender is owner of a contract/alias identity
            IdentityHolder(getAddr(contractRegistryNode)).getOwner(targetHash) == msg.sender
        , 'lacking permissions to update DID document');
        require(value != 0x0, 'Invalid value. For deactivating DIDs, please use the dedicated method.');
        require(!deactivatedDids[targetHash], 'Cannot set DID document for deactivated DID.');

        if (didDocuments[targetHash] == 0x0 && !deactivatedDids[targetHash]) { // For migration scenarios
            registeredHashes.push(targetHash);
        }
        didDocuments[targetHash] = value;
    }

    /// @notice deactivate DID document
    /// @param targetHash hash identity reference to deactivate DID for
    function deactivateDid(bytes32 targetHash) public {
        require(
            // allow if owner of registry, required for migration scenarios
            msg.sender == owner ||
            // allow if msg.sender === targetHash --> set own hash (called from identity)
            bytes32(msg.sender) == targetHash ||
            // allow if msg.sender is owner of a contract/alias identity
            IdentityHolder(getAddr(contractRegistryNode)).getOwner(targetHash) == msg.sender
        , 'lacking permissions to deactivate DID document');
        require(
            didDocuments[targetHash] != 0x0 ||
            msg.sender == owner,  // migration
        'Did is not yet activated or has already been deactivated');
        deactivatedDids[targetHash] = true;
        didDocuments[targetHash] = 0x0;
    }

    /// @notice retrieve a single entry from a mapping
    /// @param node ens namehash of contractidentities registry
    function setContractRegistryNodeHash(bytes32 node) public only_owner {
        contractRegistryNode = node;
    }

    /// @notice set value ENS registry
    /// @param ensAddress address of ENS registry
    function setEnsRegistry(address ensAddress) public only_owner {
        super.setEns(ensAddress);
    }
}
