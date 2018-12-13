/*
  BSD 2-Clause License
  
  Copyright (c) 2018, True Names Limited
  All rights reserved.
  
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
  
  * Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.
  
  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

pragma solidity ^0.4.0;

import './AbstractENS.sol';

/// @title ENS registry contract, extended with support for parent nodes and time limited uptime
/// @author evan GmbH
/// @dev based upon ENS from https://github.com/ensdomains/ens/blob/master/contracts/ENSRegistry.sol
contract TimedENS is AbstractENS {
    int256 public validPostExipireWindow = 8 weeks;

    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
        bytes32 parent;
    }

    mapping(bytes32=>Record) public records;
    mapping(bytes32=>uint256) public validUntil;

    /// Permits modifications only by the owner of the specified node.
    /// @param      node  node to check
    modifier only_owner(bytes32 node) {
        if (records[node].owner != msg.sender) throw;
        _;
    }

    /// Permits modifications only by the owner of the parent node of a node.
    /// @param      node  node to check
    modifier only_parent_owner(bytes32 node) {
        if (records[records[node].parent].owner != msg.sender) throw;
        _;
    }

    /// @notice constructs a new TimedENS registrar
    function TimedENS() {
        records[0].owner = msg.sender;
    }

    /// @notice     returns the address that owns the specified node
    /// @param      node  namehash of a node
    /// @return     address  of node owner
    function owner(bytes32 node) constant returns(address) {
        if (isAlive(node, validPostExipireWindow)) {
            return records[node].owner;
        } else {
            return address(0);
        }
    }

    /// @notice     returns parent node of given node
    /// @param      node  namehash of a node
    /// @return     address  of parent node
    function parent(bytes32 node) constant returns (bytes32) {
        return records[node].parent;
    }

    /// @notice     returns the address of resolver the specified node
    /// @param      node  namehash of node
    /// @return     address  of nodes resolver
    function resolver(bytes32 node) constant returns(address) {
        if (isAlive(node, 0)) {
            return records[node].resolver;
        } else {
            return address(0);
        }
    }

    /// @notice     returns the TTL of a node, and any records associated with it
    /// @param      node  namehash of node
    /// @return     ttl   of node value
    function ttl(bytes32 node) constant returns(uint64) {
        if (isAlive(node, 0)) {
            return records[node].ttl;
        } else {
            return 0;
        }
    }

    /// @notice     transfers ownership of a node to a new address. May only be called by the
    ///             current owner of the node
    /// @param      node   node to transfer ownership of
    /// @param      owner  address of the new owner
    function setOwner(bytes32 node, address owner) only_owner(node) {
        Transfer(node, owner);
        records[node].owner = owner;
    }

    /// @notice     transfers ownership of a subnode sha3(node, label) to a new address. May only be
    ///             called by the owner of the parent node
    /// @param      node   parent node
    /// @param      label  hash of the label specifying the subnode
    /// @param      owner  address of the new owner
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) only_owner(node) {
        var subnode = sha3(node, label);
        NewOwner(node, label, owner);
        records[subnode].owner = owner;
        records[subnode].parent = node;
    }

    /// @notice     sets the resolver address for the specified node
    /// @param      node      node to update
    /// @param      resolver  address of the resolver
    function setResolver(bytes32 node, address resolver) only_owner(node) {
        NewResolver(node, resolver);
        records[node].resolver = resolver;
    }

    /// @notice     sets the TTL for the specified node
    /// @param      node  node to update
    /// @param      ttl   TTL in seconds
    function setTTL(bytes32 node, uint64 ttl) only_owner(node) {
        NewTTL(node, ttl);
        records[node].ttl = ttl;
    }

    /// @notice     sets duration, that keeps the owner of an expired node after its expiration
    /// @param      newValidPostExipireWindow  new value to set
    function setValidPostExipireWindow(int256 newValidPostExipireWindow) public only_owner(0) {
        validPostExipireWindow = newValidPostExipireWindow;
    }

    /// @notice     sets duration, that a given node can be resolved before it expires
    /// @param      node   node to set valid until for
    /// @param      value  new value to set
    function setValidUntil(bytes32 node, uint256 value) only_parent_owner(node) {
        validUntil[node] = value;
    }

    /// @notice     checks if a given node is still alive shifted by given offset (use offset 0 for
    ///             "now")
    /// @param      hash    namehash of node
    /// @param      offset  int256 offset to add onto valid until value
    function isAlive(bytes32 hash, int256 offset) public view returns(bool) {
        if (validUntil[hash] != 0 && (uint256(int256(validUntil[hash]) + offset) < now)) {
            // found a set and expired node
            return false;
        } else if (hash == bytes32(0)) {
            // found root node --> valid
            return true;
        } else {
            // check parent
            return isAlive(records[hash].parent, offset);
        }
    }
}
