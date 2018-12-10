pragma solidity ^0.4.24;

import "./ERC735.sol";
import "./KeyHolder.sol";
import "./ClaimHolderLibrary.sol";
import "./KeyHolderLibrary.sol";

contract ClaimHolder is KeyHolder, ERC735 {

    ClaimHolderLibrary.Claims claims;

    function addClaim(
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
        return ClaimHolderLibrary.addClaim(
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

    function addClaims(
        uint256[] _topic,
        address[] _issuer,
        bytes _signature,
        bytes _data,
        uint256[] _offsets
    )
        public
    {
        ClaimHolderLibrary.addClaims(
            keyHolderData,
            claims,
            _topic,
            _issuer,
            _signature,
            _data,
            _offsets
        );
    }

    function addClaimWithMetadata(
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
        bytes32 claimId = addClaim(_topic, _scheme, _issuer, _signature, _data, _uri);
        require(this.setClaimExpirationDate(claimId, _expirationDate));
        require(this.setClaimDescription(claimId, _description));
        return claimId;
    }

    function approveClaim(bytes32 _claimId) public returns (bool success) {
        return ClaimHolderLibrary.approveClaim(keyHolderData, claims, _claimId);
    }

    function removeClaim(bytes32 _claimId) public returns (bool success) {
        return ClaimHolderLibrary.removeClaim(keyHolderData, claims, _claimId);
    }

    function rejectClaim(bytes32 _claimId, bytes32 _rejectReason) public returns (bool success) {
        return ClaimHolderLibrary.rejectClaim(keyHolderData, claims, _claimId, _rejectReason);
    }

    function setClaimDescription(bytes32 _claimId, bytes32 _description) public returns (bool success) {
        require(msg.sender == address(this));
        return ClaimHolderLibrary.setClaimDescription(keyHolderData, claims, _claimId, _description);
    }

    function setClaimExpirationDate(bytes32 _claimId, uint256 _expirationDate) public returns (bool success) {
        require(msg.sender == address(this));
        return ClaimHolderLibrary.setClaimExpirationDate(keyHolderData, claims, _claimId, _expirationDate);
    }

    function claimCreationBlock(bytes32 _claimId) public view returns (uint256 block) {
        return ClaimHolderLibrary.claimCreationBlock(claims, _claimId);
    }

    function claimCreationDate(bytes32 _claimId) public view returns (uint256 timestamp) {
        return ClaimHolderLibrary.claimCreationDate(claims, _claimId);
    }

    function getClaim(bytes32 _claimId)
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
        return ClaimHolderLibrary.getClaim(claims, _claimId);
    }

    function getClaimDescription(bytes32 _claimId) public view returns (bytes32 description) {
        return ClaimHolderLibrary.claimDescription(claims, _claimId);
    }

    function getClaimExpirationDate(bytes32 _claimId) public view returns (uint256 timestamp) {
        return ClaimHolderLibrary.claimExpirationDate(claims, _claimId);
    }

    function getClaimIdsByTopic(uint256 _topic)
        public
        view
        returns(bytes32[] claimIds)
    {
        return claims.byTopic[_topic];
    }

    function isClaimApproved(bytes32 _claimId) public view returns (bool success) {
        return ClaimHolderLibrary.isClaimApproved(claims, _claimId);
    }

    function isClaimRejected(bytes32 _claimId) 
        public 
        view 
        returns (
            bool rejected,
            bytes32 rejectReason
        )
    {
        return ClaimHolderLibrary.isClaimRejected(claims, _claimId);
    }
}
