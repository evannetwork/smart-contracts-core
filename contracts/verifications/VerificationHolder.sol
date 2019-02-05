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

    VerificationHolderLibrary.Verifications verifications;

    constructor(address _keyHolderOwner) public KeyHolder(_keyHolderOwner) {
        // just run parent class constructor
    }

    function addVerification(
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
        return VerificationHolderLibrary.addVerification(
            keyHolderData,
            verifications,
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
            verifications,
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
        returns (bytes32 verificationRequestId)
    {
        bytes32 verificationId = addVerification(_topic, _scheme, _issuer, _signature, _data, _uri);
        require(this.setVerificationExpirationDate(verificationId, _expirationDate));
        require(this.setVerificationDescription(verificationId, _description));
        return verificationId;
    }

    function approveVerification(bytes32 _verificationId) public returns (bool success) {
        return VerificationHolderLibrary.approveVerification(keyHolderData, verifications, _verificationId);
    }

    function removeVerification(bytes32 _verificationId) public returns (bool success) {
        return VerificationHolderLibrary.removeVerification(keyHolderData, verifications, _verificationId);
    }

    function rejectVerification(bytes32 _verificationId, bytes32 _rejectReason) public returns (bool success) {
        return VerificationHolderLibrary.rejectVerification(keyHolderData, verifications, _verificationId, _rejectReason);
    }

    function setVerificationDescription(bytes32 _verificationId, bytes32 _description) public returns (bool success) {
        require(msg.sender == address(this));
        return VerificationHolderLibrary.setVerificationDescription(keyHolderData, verifications, _verificationId, _description);
    }

    function setVerificationExpirationDate(bytes32 _verificationId, uint256 _expirationDate) public returns (bool success) {
        require(msg.sender == address(this));
        return VerificationHolderLibrary.setVerificationExpirationDate(keyHolderData, verifications, _verificationId, _expirationDate);
    }

    function verificationCreationBlock(bytes32 _verificationId) public view returns (uint256 block) {
        return VerificationHolderLibrary.verificationCreationBlock(verifications, _verificationId);
    }

    function verificationCreationDate(bytes32 _verificationId) public view returns (uint256 timestamp) {
        return VerificationHolderLibrary.verificationCreationDate(verifications, _verificationId);
    }

    function getVerification(bytes32 _verificationId)
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
        return VerificationHolderLibrary.getVerification(verifications, _verificationId);
    }

    function getVerificationDescription(bytes32 _verificationId) public view returns (bytes32 description) {
        return VerificationHolderLibrary.verificationDescription(verifications, _verificationId);
    }

    function getVerificationExpirationDate(bytes32 _verificationId) public view returns (uint256 timestamp) {
        return VerificationHolderLibrary.verificationExpirationDate(verifications, _verificationId);
    }

    function getVerificationIdsByTopic(uint256 _topic)
        public
        view
        returns(bytes32[] verificationIds)
    {
        return verifications.byTopic[_topic];
    }

    function isVerificationApproved(bytes32 _verificationId) public view returns (bool success) {
        return VerificationHolderLibrary.isVerificationApproved(verifications, _verificationId);
    }

    function isVerificationRejected(bytes32 _verificationId) 
        public 
        view 
        returns (
            bool rejected,
            bytes32 rejectReason
        )
    {
        return VerificationHolderLibrary.isVerificationRejected(verifications, _verificationId);
    }
}
