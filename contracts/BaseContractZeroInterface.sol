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

import "./Described.sol";
import "./Shared.sol";


contract BaseContractZeroInterface is Described, Shared {
    enum ContractState {
        Initial,
        Error,
        Draft,
        PendingApproval,
        Approved,
        Active,
        VerifyTerminated,
        Terminated
    }

    enum ConsumerState {
        Initial,
        Error,
        Draft,
        Rejected,
        Active,
        Terminated
    }

    event StateshiftEvent(uint state, address indexed partner);

    function getProvider() public constant returns (address provider);
    function getConsumerState(address) public constant returns (ConsumerState);
    function getMyState() public constant returns (ConsumerState);
    function changeConsumerState(address, ConsumerState) public;
    function changeContractState(ContractState) public;
    function isConsumer(address) public constant returns (bool);
    function inviteConsumer(address, address) public;
    function removeConsumer(address, address) public;

    function contractState() public view returns (ContractState);
    function contractType() public view returns (bytes32);
    function created() public view returns (uint);
    function consumerCount() public view returns (uint);
    function index2consumer(uint index) public view returns (address consumer);
    function consumer2index(address consumer) public view returns (uint index);
    function consumerState(address consumer) public view returns (ConsumerState);
    function allowConsumerInvite() public view returns (bool);
}
