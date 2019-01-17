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


library VerificationsRegistryLibrary {
    event VerificationAdded(bytes32 identity, bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event VerificationRemoved(bytes32 identity, bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event VerificationApproved(bytes32 identity, bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    struct Identity {
      Verifications claims;
      address link;
      address owner;
    }

    struct Identities {
      mapping (bytes32 => Identity) byId;
    }

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
        Identities storage _identities,
        bytes32 _identity,
        uint256 _topic,
        uint256 _scheme,
        address _issuer,
        bytes _signature,
        bytes _data,
        string _uri
    )
        public
        returns (bytes32 claimRequestId)
    {
        Verifications _claims = _identities.byId[_identity].claims;
        bytes32 claimId = keccak256(abi.encodePacked(_issuer, _topic, now));

        if (_claims.byId[claimId].issuer != _issuer) {
            _claims.byTopic[_topic].push(claimId);
            _claims.topicIdbyVerificationId[_topic][claimId] = _claims.byTopic[_topic].length - 1;
        }

        _claims.creationDates[claimId] = now;
        _claims.creationBlocks[claimId] = block.number;

        _claims.byId[claimId].topic = _topic;
        _claims.byId[claimId].scheme = _scheme;
        _claims.byId[claimId].issuer = _issuer;
        _claims.byId[claimId].signature = _signature;
        _claims.byId[claimId].data = _data;
        _claims.byId[claimId].uri = _uri;

        emit VerificationAdded(
            _identity,
            claimId,
            _topic,
            _scheme,
            _issuer,
            _signature,
            _data,
            _uri
        );

        return claimId;
    }

    function addVerifications(
        Identities storage _identities,
        bytes32 _identity,
        uint256[] _topic,
        address[] _issuer,
        bytes _signature,
        bytes _data,
        uint256[] _offsets
    )
        public
    {
        Verifications _claims = _identities.byId[_identity].claims;
        uint offset = 0;
        for (uint16 i = 0; i < _topic.length; i++) {
            addVerification(
                _identities,
                _identity,
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
        Identities storage _identities,
        bytes32 _identity,
        bytes32 _claimId
    )
        public
        returns (bool success)
    {
        Verifications _claims = _identities.byId[_identity].claims;
        require(_claims.byId[_claimId].issuer != address(0), "No claim exists");

        if (msg.sender != address(this) && msg.sender != _claims.byId[_claimId].issuer) {
            require(msg.sender == _identities.byId[_identity].owner, "Sender does not have ownership of identity");
        }

        emit VerificationRemoved(
            _identity,
            _claimId,
            _claims.byId[_claimId].topic,
            _claims.byId[_claimId].scheme,
            _claims.byId[_claimId].issuer,
            _claims.byId[_claimId].signature,
            _claims.byId[_claimId].data,
            _claims.byId[_claimId].uri
        );

        uint256 topic = _claims.byId[_claimId].topic;
        uint256 lastIndex = _claims.byTopic[topic].length -1;
        uint256 claimIndexAtTopic = _claims.topicIdbyVerificationId[topic][_claimId];
        if (lastIndex != 0 && lastIndex != claimIndexAtTopic) {
            _claims.byTopic[topic][claimIndexAtTopic] = _claims.byTopic[topic][lastIndex];
        }
        delete _claims.byTopic[topic][lastIndex];
        _claims.byTopic[topic].length = _claims.byTopic[topic].length--;
        delete _claims.byId[_claimId];
        return true;
    }

    function rejectVerification(
        Identities storage _identities,
        bytes32 _identity,
        bytes32 _claimId,
        bytes32 _rejectReason
    )
        public
        returns (bool success)
    {
        Verifications _claims = _identities.byId[_identity].claims;
        require(_claims.byId[_claimId].issuer != address(0), "No claim exists");
        require(_claims.rejectedVerifications[_claimId] == false, "Verification already rejected");
        if (msg.sender != address(this) && msg.sender != _claims.byId[_claimId].issuer) {
            require(msg.sender == _identities.byId[_identity].owner, "Sender does not have ownership of identity");
        }

        _claims.rejectedVerifications[_claimId] = true;
        _claims.rejectReason[_claimId] = _rejectReason;
        _claims.approvedVerifications[_claimId] = false;
        return true;
    }

    function approveVerification(
        Identities storage _identities,
        bytes32 _identity,
        bytes32 _claimId
    ) 
        public
        returns (bool success)
    {
        Verifications _claims = _identities.byId[_identity].claims;
        require(_claims.byId[_claimId].issuer != address(0), "No claim exists");
        require(_claims.rejectedVerifications[_claimId] == false, "Verification already rejected");
        if (msg.sender != address(this) && msg.sender != _claims.byId[_claimId].issuer) {
            require(msg.sender == _identities.byId[_identity].owner, "Sender does not have ownership of identity");
        }

        _claims.approvedVerifications[_claimId] = true;
        emit VerificationApproved(
            _identity,
            _claimId,
            _claims.byId[_claimId].topic,
            _claims.byId[_claimId].scheme,
            _claims.byId[_claimId].issuer,
            _claims.byId[_claimId].signature,
            _claims.byId[_claimId].data,
            _claims.byId[_claimId].uri
        );
    }


    function setVerificationDescription(
        Identities storage _identities,
        bytes32 _identity,
        bytes32 _claimId,
        bytes32 _description
    )
        public
        returns (bool success)
    {
        Verifications _claims = _identities.byId[_identity].claims;
        require(_claims.byId[_claimId].issuer != address(0), "No claim exists");

        if (msg.sender != address(this) && msg.sender != _claims.byId[_claimId].issuer) {
            require(msg.sender == _identities.byId[_identity].owner, "Sender does not have ownership of identity");
        }

        _claims.descriptions[_claimId] = _description;
        return true;
    }

    function setVerificationExpirationDate(
        Identities storage _identities,
        bytes32 _identity,
        bytes32 _claimId,
        uint256 _expirationDate
    )
        public
        returns (bool success)
    {
        Verifications _claims = _identities.byId[_identity].claims;
        require(_claims.byId[_claimId].issuer != address(0), "No claim exists");

        if (msg.sender != address(this) && msg.sender != _claims.byId[_claimId].issuer) {
            require(msg.sender == _identities.byId[_identity].owner, "Sender does not have ownership of identity");
        }

        _claims.expiringDates[_claimId] = _expirationDate;
        return true;
    }
    
    function getVerification(Identities storage _identities, bytes32 _identity, bytes32 _claimId)
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
        Verifications _claims = _identities.byId[_identity].claims;
        return (
            _claims.byId[_claimId].topic,
            _claims.byId[_claimId].scheme,
            _claims.byId[_claimId].issuer,
            _claims.byId[_claimId].signature,
            _claims.byId[_claimId].data,
            _claims.byId[_claimId].uri
        );
    }

    function isVerificationApproved(Identities storage _identities, bytes32 _identity, bytes32 _claimId)
        public
        view
        returns (bool)
    {
        Verifications _claims = _identities.byId[_identity].claims;
        return _claims.approvedVerifications[_claimId];
    }

    function isVerificationRejected(Identities storage _identities, bytes32 _identity, bytes32 _claimId)
        public
        view
        returns (
            bool rejected,
            bytes32 rejectReason
        )
    {
        Verifications _claims = _identities.byId[_identity].claims;
        rejected = _claims.rejectedVerifications[_claimId];
        rejectReason = _claims.rejectReason[_claimId];
    }

    function claimCreationBlock(Identities storage _identities, bytes32 _identity, bytes32 _claimId)
        public
        view
        returns (uint256)
    {
        Verifications _claims = _identities.byId[_identity].claims;
        return _claims.creationBlocks[_claimId];
    }

    function claimCreationDate(Identities storage _identities, bytes32 _identity, bytes32 _claimId)
        public
        view
        returns (uint256)
    {
        Verifications _claims = _identities.byId[_identity].claims;
        return _claims.creationDates[_claimId];
    }

    function claimDescription(Identities storage _identities, bytes32 _identity, bytes32 _claimId)
        public
        view
        returns (bytes32)
    {
        Verifications _claims = _identities.byId[_identity].claims;
        return _claims.descriptions[_claimId];
    }

    function claimExpirationDate(Identities storage _identities, bytes32 _identity, bytes32 _claimId)
        public
        view
        returns (uint256)
    {
        Verifications _claims = _identities.byId[_identity].claims;
        return _claims.expiringDates[_claimId];
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
