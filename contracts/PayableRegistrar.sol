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
import "./ENS.sol";


/**
 * A registrar that allocates subdomains to the first person to claim them.
 */
contract PayableRegistrar is Owned {
    uint256 public price;
    ENS public ens;
    bytes32 public rootNode;

    modifier only_label_owner(bytes32 label) {
        address currentOwner = ens.owner(keccak256(abi.encodePacked(rootNode, label)));
        require(currentOwner == 0 || currentOwner == msg.sender || this.owner() == msg.sender);
        require(msg.value == price);
        _;
    }

    /**
     * Constructor.
     * @param ensAddr The address of the ENS registry.
     * @param node The node that this registrar administers.
     */
    constructor(ENS ensAddr, bytes32 node, uint256 newPrice) public Owned() {
        ens = ensAddr;
        rootNode = node;
        price = newPrice;
    }

    /**
     * Register a name, or change the owner of an existing registration.
     * @param label The hash of the label to register.
     * @param owner The address of the new owner.
     */
    function register(bytes32 label, address owner) public payable only_label_owner(label) {
        ens.setSubnodeOwner(rootNode, label, owner);
        if (msg.sender == this.owner()) {
          owner.transfer(msg.value);
        }
    }

    function claimFunds() public only_owner {
      this.owner().transfer(this.balance);
    }
    function setPrice(uint256 newPrice) public only_owner {
      price = newPrice;
    }
}