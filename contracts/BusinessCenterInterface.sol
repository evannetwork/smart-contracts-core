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

pragma solidity 0.4.20;

import "./Core.sol";
import "./DataStoreIndex.sol";


contract BusinessCenterInterface is Owned {
    enum JoinSchema { SelfJoin, AddOnly, Handshake, JoinOrAdd }

    uint public VERSION_ID;
    JoinSchema public joinSchema;
    mapping(address => bool) public pendingJoins;
    mapping(address => bool) public pendingInvites;

    modifier only_members {
        assert(isMember(msg.sender));
        _;
    }

    function init(DataStoreIndex, JoinSchema) public;

    function join() public;
    function invite(address) public;
    function cancel() public;

    function registerContract(address _contract, address _provider, bytes32 _contractType) public;
    function registerContractMember(address _contract, address _member, bytes32 _contractType) public;
    function removeContractMember(address _contract, address _member) public;
    function migrateTo(address) public;
    function sendContractEvent(uint evetType, bytes32 contractType, address member) public;
    function getProfile(address account) public constant returns (bytes32);
    function setMyProfile(bytes32 profile) public;
    function setJoinSchema(JoinSchema) public;

    function isMember(address _member) public constant returns (bool);
    function isContract(address _contract) public constant returns (bool);
    function getMyIndex() public constant returns (DataStoreIndex);
    function getStorage() public constant returns (DataStoreIndex);
}
