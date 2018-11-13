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


contract EventHubBusinessCenter {

    enum BusinessCenterEventType {
        New,
        Cancel,
        Draft,
        Rejected,
        Approved,
        Active,
        Terminated,
        Invite,
        Modified,
        PendingJoin,
        PendingInvite
    }

    event ContractEvent(
        address sender,
        uint eventType,
        bytes32 indexed contractType,
        address indexed contractAddress,
        address indexed member);

    event MemberEvent(address sender, uint eventType, address indexed member);

    function sendContractEvent(uint eventType, bytes32 contractType, address contractAddress, address member) public {
        emit ContractEvent(msg.sender, eventType, contractType, contractAddress, member);
    }

    function sendMemberEvent(uint eventType, address member) public {
        emit MemberEvent(msg.sender, eventType, member);
    }
}
