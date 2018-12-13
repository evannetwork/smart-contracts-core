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

pragma solidity ^0.4.24;

import "./Core.sol";
import "./TimedENS.sol";

/// @title registrar that allocates subdomains to the first person to claim them, extended with support for parent nodes and time limited uptime
/// @author evan GmbH
/// @dev based upon ENS from https://github.com/ensdomains/ens/blob/master/contracts/FIFSRegistrar.sol
contract PayableRegistrar is Owned {
    TimedENS public ens;
    uint256 public price;
    bytes32 public rootNode;
    uint256 public validDuration = 52 weeks;
    int256 public validPreExipireWindow = -8 weeks;

    // @notice     permits modifications only by the owner of the specified node
    // @param      label  node to check
    modifier only_label_owner(bytes32 label) {
        address currentOwner = ens.owner(keccak256(abi.encodePacked(rootNode, label)));
        require(currentOwner == 0 || currentOwner == msg.sender || this.owner() == msg.sender);
        require(msg.value == price);
        _;
    }

    /// @notice     constructor
    /// @param      ensAddr   address of the ENS registry
    /// @param      node      node that this registrar administers
    /// @param      newPrice  price for registering domains
    constructor(TimedENS ensAddr, bytes32 node, uint256 newPrice) public Owned() {
        ens = ensAddr;
        rootNode = node;
        price = newPrice;
    }

    /// @notice     claim current funds this contract
    /// @dev        only callable by owner
    function claimFunds() public only_owner {
        this.owner().transfer(this.balance);
    }

    /// @notice     register a name, or change the owner of an existing registration
    /// @param      label  hash of the label to register
    /// @param      owner  address of the new owner
    function register(bytes32 label, address owner) public payable only_label_owner(label) {
        bytes32 fullHash = keccak256(abi.encodePacked(rootNode, label));
        // get valid time for registered node
        uint256 oldValidUntil = ens.validUntil(fullHash);

        require(
          // hash has never been claimed
          oldValidUntil == 0 ||
          // sender is current owner and node is about to expire or already expired
          // --> ens owner considers post expiration, so owner matches until expiration plus protection
          // --> is alive with pre expiration returns false from beginning of expiration until fully expired
          // ==> overlapping timeframe is from begging of pre expiration until end of post expiration protection
          ens.owner(fullHash) == msg.sender && !ens.isAlive(fullHash, validPreExipireWindow) ||
          // sender is any user, node is fully expired (everyone can buy it)
          // --> ens owner considers post expiration owner protection
          ens.owner(fullHash) == address(0) ||
          // owner of registrar calls function
          this.owner() == msg.sender
        );

        // make sender owner of subnode
        ens.setSubnodeOwner(rootNode, label, owner);

        // if oldValidUntil is expired, start anew. otherwise extend duration
        if (oldValidUntil < now) {
          oldValidUntil = now;
        }
        ens.setValidUntil(fullHash, oldValidUntil + validDuration);

        // refund given tx value if owner called
        if (msg.sender == this.owner()) {
          owner.transfer(msg.value);
        }
    }

    /// @notice     register a permanent domain, can only be doen by registar 
    /// @param      label  hash of the label to register
    /// @param      owner  address of the new owner
    function registerPermanent(bytes32 label, address owner) public only_owner {
        // make owner the owner of subnode and set duration to permanent
        ens.setSubnodeOwner(rootNode, label, owner);
        // ens.setValidUntil(keccak256(abi.encodePacked(rootNode, label)), 0);
    }

    /// @notice     set price for registering domains
    /// @param      newPrice  price to set
    function setPrice(uint256 newPrice) public only_owner {
        price = newPrice;
    }

    /// @notice     set duration, that a registered domain is owner
    /// @param      newValidDuration  new duration to set
    function setValidDuration(uint256 newValidDuration) public only_owner {
        validDuration = newValidDuration;
    }

    /// @notice     set timeframe in which a node ownership can be extended before expiration
    /// @dev        as this refers to a timewindows BEFORE node resolution timeout, this value is
    ///             negative
    /// @param      newValidPreExipireWindow  timeframe in which a node ownership can be extended
    function setValidPreExipireWindow(int256 newValidPreExipireWindow) public only_owner {
        require(newValidPreExipireWindow <= 0);
        validPreExipireWindow = newValidPreExipireWindow;
    }
}