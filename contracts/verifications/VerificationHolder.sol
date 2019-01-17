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
import "./KeyHolder.sol";
import "./VerificationHolderLibrary.sol";
import "./KeyHolderLibrary.sol";

contract VerificationHolder is KeyHolder, ERC735 {

    VerificationHolderLibrary.Verifications claims;

    function addVerification(
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
        return VerificationHolderLibrary.addVerification(
            keyHolderData,
            claims,
            _topic,
            _scheme,
            _issuer,
            _signature,
            _data,
            _uri
        );
    }

    function addVerifications(
        uint256[] _topic,
        address[] _issuer,
        bytes _signature,
        bytes _data,
        uint256[] _offsets
    )
        public
    {
        VerificationHolderLibrary.addVerifications(
            keyHolderData,
            claims,
            _topic,
            _issuer,
            _signature,
            _data,
            _offsets
        );
    }

    function addVerificationWithMetadata(
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
        bytes32 claimId = addVerification(_topic, _scheme, _issuer, _signature, _data, _uri);
        require(this.setVerificationExpirationDate(claimId, _expirationDate));
        require(this.setVerificationDescription(claimId, _description));
        return claimId;
    }

    function approveVerification(bytes32 _claimId) public returns (bool success) {
        return VerificationHolderLibrary.approveVerification(keyHolderData, claims, _claimId);
    }

    function removeVerification(bytes32 _claimId) public returns (bool success) {
        return VerificationHolderLibrary.removeVerification(keyHolderData, claims, _claimId);
    }

    function rejectVerification(bytes32 _claimId, bytes32 _rejectReason) public returns (bool success) {
        return VerificationHolderLibrary.rejectVerification(keyHolderData, claims, _claimId, _rejectReason);
    }

    function setVerificationDescription(bytes32 _claimId, bytes32 _description) public returns (bool success) {
        require(msg.sender == address(this));
        return VerificationHolderLibrary.setVerificationDescription(keyHolderData, claims, _claimId, _description);
    }

    function setVerificationExpirationDate(bytes32 _claimId, uint256 _expirationDate) public returns (bool success) {
        require(msg.sender == address(this));
        return VerificationHolderLibrary.setVerificationExpirationDate(keyHolderData, claims, _claimId, _expirationDate);
    }

    function claimCreationBlock(bytes32 _claimId) public view returns (uint256 block) {
        return VerificationHolderLibrary.claimCreationBlock(claims, _claimId);
    }

    function claimCreationDate(bytes32 _claimId) public view returns (uint256 timestamp) {
        return VerificationHolderLibrary.claimCreationDate(claims, _claimId);
    }

    function getVerification(bytes32 _claimId)
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
        return VerificationHolderLibrary.getVerification(claims, _claimId);
    }

    function getVerificationDescription(bytes32 _claimId) public view returns (bytes32 description) {
        return VerificationHolderLibrary.claimDescription(claims, _claimId);
    }

    function getVerificationExpirationDate(bytes32 _claimId) public view returns (uint256 timestamp) {
        return VerificationHolderLibrary.claimExpirationDate(claims, _claimId);
    }

    function getVerificationIdsByTopic(uint256 _topic)
        public
        view
        returns(bytes32[] claimIds)
    {
        return claims.byTopic[_topic];
    }

    function isVerificationApproved(bytes32 _claimId) public view returns (bool success) {
        return VerificationHolderLibrary.isVerificationApproved(claims, _claimId);
    }

    function isVerificationRejected(bytes32 _claimId) 
        public 
        view 
        returns (
            bool rejected,
            bytes32 rejectReason
        )
    {
        return VerificationHolderLibrary.isVerificationRejected(claims, _claimId);
    }
}
