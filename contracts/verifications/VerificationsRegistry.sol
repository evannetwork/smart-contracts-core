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

import "./ERC735.sol";
import "./VerificationsRegistryLibrary.sol";
import "./IdentityHolder.sol";


contract VerificationsRegistry is IdentityHolder {
    function addVerification(
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
        return VerificationsRegistryLibrary.addVerification(
            identities,
            _identity,
            _topic,
            _scheme,
            _issuer,
            _signature,
            _data,
            _uri
        );
    }

    function addVerifications(
        bytes32 _identity,
        uint256[] _topic,
        address[] _issuer,
        bytes _signature,
        bytes _data,
        uint256[] _offsets
    )
        public
    {
        VerificationsRegistryLibrary.addVerifications(
            identities,
            _identity,
            _topic,
            _issuer,
            _signature,
            _data,
            _offsets
        );
    }

    function addVerificationWithMetadata(
        bytes32 _identity,
        uint256 _topic,
        uint256 _scheme,
        address _issuer,
        bytes _signature,
        bytes _data,
        string _uri,
        uint256 _expirationDate,
        bytes32 _description
        )
        public
        returns (bytes32 claimRequestId)
    {
        bytes32 claimId = addVerification(_identity, _topic, _scheme, _issuer, _signature, _data, _uri);
        require(VerificationsRegistryLibrary.setVerificationDescription(identities, _identity, claimId, _description));
        require(VerificationsRegistryLibrary.setVerificationExpirationDate(identities, _identity, claimId, _expirationDate));
        return claimId;
    }

    function approveVerification(bytes32 _identity, bytes32 _claimId) public returns (bool success) {
        return VerificationsRegistryLibrary.approveVerification(identities, _identity, _claimId);
    }

    function removeVerification(bytes32 _identity, bytes32 _claimId) public returns (bool success) {
        return VerificationsRegistryLibrary.removeVerification(identities, _identity, _claimId);
    }

    function rejectVerification(bytes32 _identity, bytes32 _claimId, bytes32 _rejectReason) public returns (bool success) {
        return VerificationsRegistryLibrary.rejectVerification(identities, _identity, _claimId, _rejectReason);
    }

    function claimCreationBlock(bytes32 _identity, bytes32 _claimId) public view returns (uint256 block) {
        return VerificationsRegistryLibrary.claimCreationBlock(identities, _identity, _claimId);
    }

    function claimCreationDate(bytes32 _identity, bytes32 _claimId) public view returns (uint256 timestamp) {
        return VerificationsRegistryLibrary.claimCreationDate(identities, _identity, _claimId);
    }

    function getVerification(bytes32 _identity, bytes32 _claimId)
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
        return VerificationsRegistryLibrary.getVerification(identities, _identity, _claimId);
    }

    function getVerificationDescription(bytes32 _identity, bytes32 _claimId) public view returns (bytes32 description) {
        return VerificationsRegistryLibrary.claimDescription(identities, _identity, _claimId);
    }

    function getVerificationExpirationDate(bytes32 _identity, bytes32 _claimId) public view returns (uint256 timestamp) {
        return VerificationsRegistryLibrary.claimExpirationDate(identities, _identity, _claimId);
    }

    function getVerificationIdsByTopic(bytes32 _identity, uint256 _topic)
        public
        view
        returns(bytes32[] claimIds)
    {
        return identities.byId[_identity].claims.byTopic[_topic];
    }

    function isVerificationApproved(bytes32 _identity, bytes32 _claimId) public view returns (bool success) {
        return VerificationsRegistryLibrary.isVerificationApproved(identities, _identity, _claimId);
    }

    function isVerificationRejected(bytes32 _identity, bytes32 _claimId) 
        public 
        view 
        returns (
            bool rejected,
            bytes32 rejectReason
        )
    {
        return VerificationsRegistryLibrary.isVerificationRejected(identities, _identity, _claimId);
    }
}
