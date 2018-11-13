pragma solidity ^0.4.24;

import "./KeyHolderLibrary.sol";


library ClaimHolderLibrary {
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimApproved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer; // msg.sender
        bytes signature; // this.address + topic + data
        bytes data;
        string uri;
    }

    struct Claims {
        mapping (bytes32 => Claim) byId;
        mapping (uint256 => bytes32[]) byTopic;
        mapping (uint256 => mapping ( bytes32 => uint256 )) topicIdbyClaimId;
        mapping (bytes32 => bool) approvedClaims;
        mapping (uint256 => uint256) creationDates;
    }


    function addClaim(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Claims storage _claims,
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
        // commented out because check maeks no sense, therfore the foreing identity has to add the current executor as claim signer key
        /*if (msg.sender != address(this)) {
            require(KeyHolderLibrary.keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 3), "Sender does not have claim signer key");
        }*/

        bytes32 claimId = keccak256(abi.encodePacked(_issuer, _topic));

        if (_claims.byId[claimId].issuer != _issuer) {
            _claims.byTopic[_topic].push(claimId);
            _claims.topicIdbyClaimId[_topic][claimId] = _claims.byTopic[_topic].length -1;
        } else {
            if(keccak256(_claims.byId[claimId].signature) != keccak256(_signature) || keccak256(_claims.byId[claimId].uri) != keccak256(_uri)) {
                if(_claims.approvedClaims[claimId]) {
                    delete _claims.approvedClaims[claimId];
                }
            } else {
                return claimId;
            }
        }

        _claims.creationDates[claimId] = now;

        _claims.byId[claimId].topic = _topic;
        _claims.byId[claimId].scheme = _scheme;
        _claims.byId[claimId].issuer = _issuer;
        _claims.byId[claimId].signature = _signature;
        _claims.byId[claimId].data = _data;
        _claims.byId[claimId].uri = _uri;

        emit ClaimAdded(
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

    function addClaims(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Claims storage _claims,
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
            addClaim(
                _keyHolderData,
                _claims,
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

    function removeClaim(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Claims storage _claims,
        bytes32 _claimId
    )
        public
        returns (bool success)
    {

        require(_claims.byId[_claimId].issuer != address(0), "No claim exists");

        if (msg.sender != address(this) && msg.sender != _claims.byId[_claimId].issuer) {
            require(KeyHolderLibrary.keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");
        }

        emit ClaimRemoved(
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
        uint256 claimIndexAtTopic = _claims.topicIdbyClaimId[topic][_claimId];
        if (lastIndex != 0 && lastIndex != claimIndexAtTopic) {
            _claims.byTopic[topic][claimIndexAtTopic] = _claims.byTopic[topic][lastIndex];
        }
        delete _claims.byTopic[topic][lastIndex];
        _claims.byTopic[topic].length = _claims.byTopic[topic].length--;
        delete _claims.byId[_claimId];
        return true;
    }

    function approveClaim(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Claims storage _claims,
        bytes32 _claimId
    ) 
        public
        returns (bool success)
    {

        require(_claims.byId[_claimId].issuer != address(0), "No claim exists");

        if (msg.sender != address(this) && msg.sender != _claims.byId[_claimId].issuer) {
            require(KeyHolderLibrary.keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");
        }

        _claims.approvedClaims[_claimId] = true;
        emit ClaimApproved(
            _claimId,
            _claims.byId[_claimId].topic,
            _claims.byId[_claimId].scheme,
            _claims.byId[_claimId].issuer,
            _claims.byId[_claimId].signature,
            _claims.byId[_claimId].data,
            _claims.byId[_claimId].uri
        );
    }


    function getClaim(Claims storage _claims, bytes32 _claimId)
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
            _claims.byId[_claimId].topic,
            _claims.byId[_claimId].scheme,
            _claims.byId[_claimId].issuer,
            _claims.byId[_claimId].signature,
            _claims.byId[_claimId].data,
            _claims.byId[_claimId].uri
        );
    }

    function isClaimApproved(Claims storage _claims, bytes32 _claimId)
        public
        view
        returns (bool)
    {
        return _claims.approvedClaims[_claimId];
    }

    function claimCreationDate(Claims storage _claims, bytes32 _claimId)
        public
        view
        returns (bool)
    {
        return _claims.creationDates[_claimId];
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
