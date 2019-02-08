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
        returns (bytes32 verificationRequestId)
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
        bytes32 _description,
        bool _disableSubVerifications
        )
        public
        returns (bytes32 verificationRequestId)
    {
        bytes32 verificationId = addVerification(_identity, _topic, _scheme, _issuer, _signature, _data, _uri);
        require(VerificationsRegistryLibrary.setVerificationDescription(identities, _identity, verificationId, _description));
        require(VerificationsRegistryLibrary.setDisableSubVerifications(identities, _identity, verificationId, _disableSubVerifications));
        require(VerificationsRegistryLibrary.setVerificationExpirationDate(identities, _identity, verificationId, _expirationDate));
        return verificationId;
    }

    function approveVerification(bytes32 _identity, bytes32 _verificationId) public returns (bool success) {
        return VerificationsRegistryLibrary.approveVerification(identities, _identity, _verificationId);
    }

    function removeVerification(bytes32 _identity, bytes32 _verificationId) public returns (bool success) {
        return VerificationsRegistryLibrary.removeVerification(identities, _identity, _verificationId);
    }

    function rejectVerification(bytes32 _identity, bytes32 _verificationId, bytes32 _rejectReason) public returns (bool success) {
        return VerificationsRegistryLibrary.rejectVerification(identities, _identity, _verificationId, _rejectReason);
    }

    function verificationCreationBlock(bytes32 _identity, bytes32 _verificationId) public view returns (uint256 block) {
        return VerificationsRegistryLibrary.verificationCreationBlock(identities, _identity, _verificationId);
    }

    function verificationCreationDate(bytes32 _identity, bytes32 _verificationId) public view returns (uint256 timestamp) {
        return VerificationsRegistryLibrary.verificationCreationDate(identities, _identity, _verificationId);
    }

    function getVerification(bytes32 _identity, bytes32 _verificationId)
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
        return VerificationsRegistryLibrary.getVerification(identities, _identity, _verificationId);
    }

    function getVerificationDescription(bytes32 _identity, bytes32 _verificationId) public view returns (bytes32 description) {
        return VerificationsRegistryLibrary.verificationDescription(identities, _identity, _verificationId);
    }

    function getDisableSubVerifications(bytes32 _identity, bytes32 _verificationId) public view returns (bool disableSubVerifications) {
        return VerificationsRegistryLibrary.disableSubVerifications(identities, _identity, _verificationId);
    }

    function getVerificationExpirationDate(bytes32 _identity, bytes32 _verificationId) public view returns (uint256 timestamp) {
        return VerificationsRegistryLibrary.verificationExpirationDate(identities, _identity, _verificationId);
    }

    function getVerificationIdsByTopic(bytes32 _identity, uint256 _topic)
        public
        view
        returns(bytes32[] verificationIds)
    {
        return identities.byId[_identity].verifications.byTopic[_topic];
    }

    function isVerificationApproved(bytes32 _identity, bytes32 _verificationId) public view returns (bool success) {
        return VerificationsRegistryLibrary.isVerificationApproved(identities, _identity, _verificationId);
    }

    function isVerificationRejected(bytes32 _identity, bytes32 _verificationId) 
        public 
        view 
        returns (
            bool rejected,
            bytes32 rejectReason
        )
    {
        return VerificationsRegistryLibrary.isVerificationRejected(identities, _identity, _verificationId);
    }
}
