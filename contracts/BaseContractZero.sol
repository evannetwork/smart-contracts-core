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

import "./BaseContractZeroInterface.sol";
import "./BaseContractZeroLibrary.sol";
import "./EnsReader.sol";


contract BaseContractZero is BaseContractZeroInterface, EnsReader {
    BaseContractZeroLibrary.Data baseContractZeroLibraryData;

    modifier in_state(ContractState _state) {
        assert(baseContractZeroLibraryData.contractState == _state);
        _;
    }
    modifier not_in_state(ContractState _state) {
        assert(baseContractZeroLibraryData.contractState != _state);
        _;
    }

    constructor(address _provider, bytes32 _contractType, bytes32 _contractDescription, address ensAddress) public {
        baseContractZeroLibraryData.contractState = ContractState.Draft;
        baseContractZeroLibraryData.created = now;
        baseContractZeroLibraryData.contractType = _contractType;
        contractDescription = _contractDescription;
        baseContractZeroLibraryData.consumerState[_provider] = ConsumerState.Draft;

        // add to internal consumer mapping
        uint id = ++baseContractZeroLibraryData.consumerCount;
        baseContractZeroLibraryData.consumer2index[_provider] = id;
        baseContractZeroLibraryData.index2consumer[id] = _provider;

        setEns(ensAddress);
    }

    // new getter
    function contractState() public view returns (ContractState) {
        return baseContractZeroLibraryData.contractState;
    }

    function contractType() public view returns (bytes32) {
        return baseContractZeroLibraryData.contractType;
    }

    function created() public view returns (uint) {
        return baseContractZeroLibraryData.created;
    }

    function consumerCount() public view returns (uint) {
        return baseContractZeroLibraryData.consumerCount;
    }

    function index2consumer(uint index) public view returns (address consumer) {
        return baseContractZeroLibraryData.index2consumer[index];
    }

    function consumer2index(address consumer) public view returns (uint index) {
        return baseContractZeroLibraryData.consumer2index[consumer];
    }

    function consumerState(address consumer) public view returns (ConsumerState) {
        return baseContractZeroLibraryData.consumerState[consumer];
    }

    function allowConsumerInvite() public view returns (bool) {
        return baseContractZeroLibraryData.allowConsumerInvite;
    }
    // /new getter
    
    function setAllowConsumerInvite(bool allowConsumerInvite) public auth {
        baseContractZeroLibraryData.allowConsumerInvite = allowConsumerInvite;
    }

    function getProvider() public constant returns (address provider) {
        return owner;
    }

    function changeConsumerState(address consumer, ConsumerState state) public auth {
        BaseContractZeroLibrary.changeConsumerState(baseContractZeroLibraryData, consumer, state);
    }

    function changeContractState(ContractState newState) public auth {
        baseContractZeroLibraryData.contractState = newState;
        emit StateshiftEvent(uint(newState), msg.sender);
    }

    function isConsumer(address consumer) public constant returns (bool) {
        return baseContractZeroLibraryData.consumer2index[consumer] != 0;
    }

    function getConsumerState(address consumer) public constant returns (ConsumerState state) {
        return baseContractZeroLibraryData.consumerState[consumer];
    }

    function getMyState() public constant returns (ConsumerState state) {
        if (msg.sender == owner) {
            return ConsumerState.Active;
        } else {
            return baseContractZeroLibraryData.consumerState[msg.sender];
        }
    }

    function inviteConsumer(address consumer, address businessCenter) public {
        BaseContractZeroLibrary.inviteConsumer(baseContractZeroLibraryData, consumer, businessCenter);
    }

    function removeConsumer(address consumer, address businessCenter) public auth {
        BaseContractZeroLibrary.removeConsumer(baseContractZeroLibraryData, consumer, businessCenter);
    }
}
