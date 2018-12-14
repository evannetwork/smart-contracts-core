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
import "./ClaimsRegistryLibrary.sol";
import "./IdentityHolder.sol";


contract ClaimsRegistry is IdentityHolder {
    function addClaim(
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
        return ClaimsRegistryLibrary.addClaim(
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

    function addClaims(
        bytes32 _identity,
        uint256[] _topic,
        address[] _issuer,
        bytes _signature,
        bytes _data,
        uint256[] _offsets
    )
        public
    {
        ClaimsRegistryLibrary.addClaims(
            identities,
            _identity,
            _topic,
            _issuer,
            _signature,
            _data,
            _offsets
        );
    }

    function addClaimWithMetadata(
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
        bytes32 claimId = addClaim(_identity, _topic, _scheme, _issuer, _signature, _data, _uri);
        require(ClaimsRegistryLibrary.setClaimDescription(identities, _identity, claimId, _description));
        require(ClaimsRegistryLibrary.setClaimExpirationDate(identities, _identity, claimId, _expirationDate));
        return claimId;
    }

    function approveClaim(bytes32 _identity, bytes32 _claimId) public returns (bool success) {
        return ClaimsRegistryLibrary.approveClaim(identities, _identity, _claimId);
    }

    function removeClaim(bytes32 _identity, bytes32 _claimId) public returns (bool success) {
        return ClaimsRegistryLibrary.removeClaim(identities, _identity, _claimId);
    }

    function rejectClaim(bytes32 _identity, bytes32 _claimId, bytes32 _rejectReason) public returns (bool success) {
        return ClaimsRegistryLibrary.rejectClaim(identities, _identity, _claimId, _rejectReason);
    }

    function claimCreationBlock(bytes32 _identity, bytes32 _claimId) public view returns (uint256 block) {
        return ClaimsRegistryLibrary.claimCreationBlock(identities, _identity, _claimId);
    }

    function claimCreationDate(bytes32 _identity, bytes32 _claimId) public view returns (uint256 timestamp) {
        return ClaimsRegistryLibrary.claimCreationDate(identities, _identity, _claimId);
    }

    function getClaim(bytes32 _identity, bytes32 _claimId)
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
        return ClaimsRegistryLibrary.getClaim(identities, _identity, _claimId);
    }

    function getClaimDescription(bytes32 _identity, bytes32 _claimId) public view returns (bytes32 description) {
        return ClaimsRegistryLibrary.claimDescription(identities, _identity, _claimId);
    }

    function getClaimExpirationDate(bytes32 _identity, bytes32 _claimId) public view returns (uint256 timestamp) {
        return ClaimsRegistryLibrary.claimExpirationDate(identities, _identity, _claimId);
    }

    function getClaimIdsByTopic(bytes32 _identity, uint256 _topic)
        public
        view
        returns(bytes32[] claimIds)
    {
        return identities.byId[_identity].claims.byTopic[_topic];
    }

    function isClaimApproved(bytes32 _identity, bytes32 _claimId) public view returns (bool success) {
        return ClaimsRegistryLibrary.isClaimApproved(identities, _identity, _claimId);
    }

    function isClaimRejected(bytes32 _identity, bytes32 _claimId) 
        public 
        view 
        returns (
            bool rejected,
            bytes32 rejectReason
        )
    {
        return ClaimsRegistryLibrary.isClaimRejected(identities, _identity, _claimId);
    }
}
