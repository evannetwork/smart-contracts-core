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

import "./KeyHolderLibrary.sol";


library VerificationHolderLibrary {
    event VerificationAdded(bytes32 indexed verificationId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event VerificationRemoved(bytes32 indexed verificationId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event VerificationApproved(bytes32 indexed verificationId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    struct Verification {
        uint256 topic;
        uint256 scheme;
        address issuer; // msg.sender
        bytes signature; // this.address + topic + data
        bytes data;
        string uri;
    }

    struct Verifications {
        mapping (bytes32 => Verification) byId;
        mapping (uint256 => bytes32[]) byTopic;
        mapping (uint256 => mapping ( bytes32 => uint256 )) topicIdbyVerificationId;
        mapping (bytes32 => bool) approvedVerifications;
        mapping (bytes32 => uint256) creationDates;
        mapping (bytes32 => uint256) creationBlocks;
        mapping (bytes32 => bytes32) descriptions;
        mapping (bytes32 => uint256) expiringDates;
        mapping (bytes32 => bool) rejectedVerifications;
        mapping (bytes32 => bytes32) rejectReason;
    }


    function addVerification(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Verifications storage _verifications,
        uint256 _topic,
        uint256 _scheme,
        address _issuer,
        bytes _signature,
        bytes _data,
        string _uri
    )
        public
        returns (bytes32 verificationRequestId)
    {
        bytes32 verificationId = keccak256(abi.encodePacked(_issuer, _topic, now));

        if (_verifications.byId[verificationId].issuer != _issuer) {
            _verifications.byTopic[_topic].push(verificationId);
            _verifications.topicIdbyVerificationId[_topic][verificationId] = _verifications.byTopic[_topic].length - 1;
        }

        _verifications.creationDates[verificationId] = now;
        _verifications.creationBlocks[verificationId] = block.number;

        _verifications.byId[verificationId].topic = _topic;
        _verifications.byId[verificationId].scheme = _scheme;
        _verifications.byId[verificationId].issuer = _issuer;
        _verifications.byId[verificationId].signature = _signature;
        _verifications.byId[verificationId].data = _data;
        _verifications.byId[verificationId].uri = _uri;

        emit VerificationAdded(
            verificationId,
            _topic,
            _scheme,
            _issuer,
            _signature,
            _data,
            _uri
        );

        return verificationId;
    }

    function addVerifications(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Verifications storage _verifications,
        uint256[] _topic,
        address[] _issuer,
        bytes _signature,
        bytes _data,
        uint256[] _offsets
    )
        public
    {
        uint offset = 0;
        for (uint16 i = 0; i < _topic.length; i++) {
            addVerification(
                _keyHolderData,
                _verifications,
                _topic[i],
                1,
                _issuer[i],
                getBytes(_signature, (i * 65), 65),
                getBytes(_data, offset, _offsets[i]),
                ""
            );
            offset += _offsets[i];
        }
    }

    function removeVerification(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Verifications storage _verifications,
        bytes32 _verificationId
    )
        public
        returns (bool success)
    {

        require(_verifications.byId[_verificationId].issuer != address(0), "No verification exists");

        if (msg.sender != address(this) && msg.sender != _verifications.byId[_verificationId].issuer) {
            require(KeyHolderLibrary.keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");
        }

        emit VerificationRemoved(
            _verificationId,
            _verifications.byId[_verificationId].topic,
            _verifications.byId[_verificationId].scheme,
            _verifications.byId[_verificationId].issuer,
            _verifications.byId[_verificationId].signature,
            _verifications.byId[_verificationId].data,
            _verifications.byId[_verificationId].uri
        );

        uint256 topic = _verifications.byId[_verificationId].topic;
        uint256 lastIndex = _verifications.byTopic[topic].length -1;
        uint256 verificationIndexAtTopic = _verifications.topicIdbyVerificationId[topic][_verificationId];
        if (lastIndex != 0 && lastIndex != verificationIndexAtTopic) {
            _verifications.byTopic[topic][verificationIndexAtTopic] = _verifications.byTopic[topic][lastIndex];
        }
        delete _verifications.byTopic[topic][lastIndex];
        _verifications.byTopic[topic].length = _verifications.byTopic[topic].length--;
        delete _verifications.byId[_verificationId];
        return true;
    }

    function rejectVerification(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Verifications storage _verifications,
        bytes32 _verificationId,
        bytes32 _rejectReason
    )
        public
        returns (bool success)
    {

        require(_verifications.byId[_verificationId].issuer != address(0), "No verification exists");
        require(_verifications.rejectedVerifications[_verificationId] == false, "Verification already rejected");
        if (msg.sender != address(this) && msg.sender != _verifications.byId[_verificationId].issuer) {
            require(KeyHolderLibrary.keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");
        }

        _verifications.rejectedVerifications[_verificationId] = true;
        _verifications.rejectReason[_verificationId] = _rejectReason;
        _verifications.approvedVerifications[_verificationId] = false;
        return true;
    }

    function approveVerification(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Verifications storage _verifications,
        bytes32 _verificationId
    ) 
        public
        returns (bool success)
    {

        require(_verifications.byId[_verificationId].issuer != address(0), "No verification exists");
        require(_verifications.rejectedVerifications[_verificationId] == false, "Verification already rejected");
        if (msg.sender != address(this) && msg.sender != _verifications.byId[_verificationId].issuer) {
            require(KeyHolderLibrary.keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");
        }

        _verifications.approvedVerifications[_verificationId] = true;
        emit VerificationApproved(
            _verificationId,
            _verifications.byId[_verificationId].topic,
            _verifications.byId[_verificationId].scheme,
            _verifications.byId[_verificationId].issuer,
            _verifications.byId[_verificationId].signature,
            _verifications.byId[_verificationId].data,
            _verifications.byId[_verificationId].uri
        );
    }


    function setVerificationDescription(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Verifications storage _verifications,
        bytes32 _verificationId,
        bytes32 _description
    )
        public
        returns (bool success)
    {
        require(_verifications.byId[_verificationId].issuer != address(0), "No verification exists");

        if (msg.sender != address(this) && msg.sender != _verifications.byId[_verificationId].issuer) {
            require(KeyHolderLibrary.keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");
        }

        _verifications.descriptions[_verificationId] = _description;
        return true;
    }

    function setVerificationExpirationDate(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Verifications storage _verifications,
        bytes32 _verificationId,
        uint256 _expirationDate
    )
        public
        returns (bool success)
    {
        require(_verifications.byId[_verificationId].issuer != address(0), "No verification exists");

        if (msg.sender != address(this) && msg.sender != _verifications.byId[_verificationId].issuer) {
            require(KeyHolderLibrary.keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");
        }

        _verifications.expiringDates[_verificationId] = _expirationDate;
        return true;
    }
    
    function getVerification(Verifications storage _verifications, bytes32 _verificationId)
        public
        view
        returns(
          uint256 topic,
          uint256 scheme,
          address issuer,
          bytes signature,
          bytes data,
          string uri
        )
    {
        return (
            _verifications.byId[_verificationId].topic,
            _verifications.byId[_verificationId].scheme,
            _verifications.byId[_verificationId].issuer,
            _verifications.byId[_verificationId].signature,
            _verifications.byId[_verificationId].data,
            _verifications.byId[_verificationId].uri
        );
    }

    function isVerificationApproved(Verifications storage _verifications, bytes32 _verificationId)
        public
        view
        returns (bool)
    {
        return _verifications.approvedVerifications[_verificationId];
    }

    function isVerificationRejected(Verifications storage _verifications, bytes32 _verificationId)
        public
        view
        returns (
            bool rejected,
            bytes32 rejectReason
        )
    {
        rejected = _verifications.rejectedVerifications[_verificationId];
        rejectReason = _verifications.rejectReason[_verificationId];
    }

    function verificationCreationBlock(Verifications storage _verifications, bytes32 _verificationId)
        public
        view
        returns (uint256)
    {
        return _verifications.creationBlocks[_verificationId];
    }

    function verificationCreationDate(Verifications storage _verifications, bytes32 _verificationId)
        public
        view
        returns (uint256)
    {
        return _verifications.creationDates[_verificationId];
    }

    function verificationDescription(Verifications storage _verifications, bytes32 _verificationId)
        public
        view
        returns (bytes32)
    {
        return _verifications.descriptions[_verificationId];
    }

    function verificationExpirationDate(Verifications storage _verifications, bytes32 _verificationId)
        public
        view
        returns (uint256)
    {
        return _verifications.expiringDates[_verificationId];
    }

    function getBytes(bytes _str, uint256 _offset, uint256 _length)
        internal
        pure
        returns (bytes)
    {
        bytes memory sig = new bytes(_length);
        uint256 j = 0;
        for (uint256 k = _offset; k < _offset + _length; k++) {
            sig[j] = _str[k];
            j++;
        }
        return sig;
    }
}
