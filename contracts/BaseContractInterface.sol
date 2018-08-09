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

import "./Described.sol";
import "./Shared.sol";


contract BaseContractInterface is Described, Shared {
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

    ContractState public contractState;
    bytes32 public contractType;
    uint public created;
    uint public consumerCount;
    mapping(uint=>address) public index2consumer;
    mapping(address=>uint) public consumer2index;
    mapping (address => ConsumerState) public consumerState;
    bool public allowConsumerInvite;

    event StateshiftEvent(uint state, address indexed partner);

    function getProvider() public constant returns (address provider);
    function getConsumerState(address) public constant returns (ConsumerState);
    function getMyState() public constant returns (ConsumerState);
    function changeConsumerState(address, ConsumerState) public;
    function changeContractState(ContractState) public;
    function isConsumer(address) public constant returns (bool);
    function inviteConsumer(address, address) public;
    function removeConsumer(address) public;


    modifier in_state(ContractState _state) {
        assert(contractState == _state);
        _;
    }
    modifier not_in_state(ContractState _state) {
        assert(contractState != _state);
        _;
    }
}
