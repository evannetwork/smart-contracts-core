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

pragma solidity 0.4.24;

import "./BaseContract.sol";
import "./EventHubBusinessCenter.sol";
import "./ServiceContractInterface.sol";


contract ServiceContract is ServiceContractInterface, BaseContract {
    bytes32 public constant EVENTHUB_LABEL =
        0xea14ea6d138254c1a2931c6a19f6888c7b52f512d165cfa428183a53dd9dfb8c; //web3.utils.soliditySha3('events')

    constructor(address _provider, bytes32 _contractType, bytes32 _contractDescription, address ensAddress) public
            BaseContract(_provider, _contractType, _contractDescription, ensAddress) {
        contractState = ContractState.Draft;
        created = now;
    }

    function sendAnswer(bytes32 answerHash, uint256 callId, uint256 parentAnswer) public auth {
        uint256 answerNumber = calls[callId].answerCount++;
        calls[callId].answers[answerNumber].hash = answerHash;
        calls[callId].answers[answerNumber].owner = msg.sender;
        calls[callId].answers[answerNumber].created = now;
        calls[callId].answers[answerNumber].parent = parentAnswer;
        emit ServiceContractEvent(callId, answerNumber);
    }
    
    function sendCall(bytes32 callHash) public auth {
        uint256 index = callCount++;
        calls[index].hash = callHash;
        calls[index].owner = msg.sender;
        calls[index].created = now;
        emit ServiceContractEvent(0, index);
    }

    function setMultiSharing(bytes32 sharingId, bytes32 _sharing) public auth {
        // allow only updates to own sharings
        // sharing are created per call, so the call owner is the sharing owner
        assert(calls[uint256(sharingId)].owner == msg.sender);
        multiSharings[sharingId] = _sharing;
    }

    function setService(address _businessCenter, bytes32 hash) public auth in_state(ContractState.Draft) {
        service = hash;
        BusinessCenterInterface(_businessCenter).sendContractEvent(
            uint(EventHubBusinessCenter.BusinessCenterEventType.Modified), contractType, msg.sender);
    }

    function getAnswers(uint256 callId, uint256 offset) public constant returns (
            bytes32[10] hash,
            address[10] owner,
            uint[10] created,
            uint256[10] parent,
            uint256 totalCount) {
        totalCount = calls[callId].answerCount;
        for (uint256 i = 0; i < 10; i++) {
            hash[i] = calls[callId].answers[i + offset].hash;
            owner[i] = calls[callId].answers[i + offset].owner;
            created[i] = calls[callId].answers[i + offset].created;
            parent[i] = calls[callId].answers[i + offset].parent;
        }
    }

    function getCalls(uint256 offset) public constant returns (
            bytes32[10] hash,
            address[10] owner,
            uint[10] created,
            uint256[10] answerCount,
            bytes32[10] sharings,
            uint256 totalCount) {
        totalCount = callCount;
        for (uint256 i = 0; i < 10; i++) {
            hash[i] = calls[i + offset].hash;
            owner[i] = calls[i + offset].owner;
            created[i] = calls[i + offset].created;
            answerCount[i] = calls[i + offset].answerCount;
            sharings[i] = multiSharings[bytes32(i + offset)];
        }
    }
}
