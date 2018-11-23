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

contract AbstractENS {
    function owner(bytes32) public constant returns(address);
    function resolver(bytes32) public constant returns(address);
    function ttl(bytes32) public constant returns(uint64);
    function setOwner(bytes32, address) public;
    function setSubnodeOwner(bytes32, bytes32, address) public;
    function setResolver(bytes32, address) public;
    function setTTL(bytes32, uint64) public;

    event Transfer(bytes32 indexed node, address newOwner);
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address newOwner);
    event NewResolver(bytes32 indexed node, address newResolver);
    event NewTTL(bytes32 indexed node, uint64 newTtl);
}
