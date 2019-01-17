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


contract ERC735 {

    event VerificationRequested(uint256 indexed verificationRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event VerificationAdded(bytes32 indexed verificationId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event VerificationRemoved(bytes32 indexed verificationId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event VerificationChanged(bytes32 indexed verificationId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    struct Verification {
        uint256 topic;
        uint256 scheme;
        address issuer; // msg.sender
        bytes signature; // this.address + topic + data
        bytes data;
        string uri;
    }

    function getVerification(bytes32 _verificationId) public view returns(uint256 topic, uint256 scheme, address issuer, bytes signature, bytes data, string uri);
    function getVerificationIdsByTopic(uint256 _topic) public view returns(bytes32[] verificationIds);
    function addVerification(uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri) public returns (bytes32 verificationRequestId);
    function removeVerification(bytes32 _verificationId) public returns (bool success);
}
