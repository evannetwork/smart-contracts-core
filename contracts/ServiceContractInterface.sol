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

import "./BaseContractInterface.sol";
import "./MultiShared.sol";

contract ServiceContractInterface is BaseContractInterface, MultiShared {
    bytes32 public service;
    // total count of all threads
    uint256 public callCount;
    // all calls
    mapping(uint256 => bytes32) public calls;
    // [7] == 3 --> call 7 has 3 answers
    mapping(uint256 => uint256) public answersCountPerCall;
    // [7[1] == 0x123 --> second answer to mail 7 is 0x123
    mapping(uint256 => mapping(uint256 => bytes32)) public answersPerCall;
    // track owner of sharings
    mapping(bytes32 => address) public multiSharingsOwner;

    event ServiceContractEvent(uint indexed parentId, uint256 entryId);

    function setService(address _businessCenter, bytes32 hash) public;
    function sendAnswer(bytes32 answerHash, uint256 callId) public;
    function sendCall(bytes32 callHash) public;
    function getAnswers(uint256 callId, uint256 offset) public constant returns (bytes32[10] page, uint256 totalCount);
    function getCalls(uint256 offset) public constant returns (bytes32[10] page, bytes32[10] sharings, uint256 totalCount);
}
