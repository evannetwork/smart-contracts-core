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

import "./VerificationHolder.sol";


contract VerificationVerifier {

    event VerificationValid(VerificationHolder _identity, uint256 topic);
    event VerificationInvalid(VerificationHolder _identity, uint256 topic);

    VerificationHolder public trustedVerificationHolder;

    constructor(address _trustedVerificationHolder) public {
        trustedVerificationHolder = VerificationHolder(_trustedVerificationHolder);
    }

    function checkVerification(VerificationHolder _identity, uint256 topic)
        public
        returns (bool verificationValid)
    {
        if (verificationIsValid(_identity, topic)) {
            emit VerificationValid(_identity, topic);
            return true;
        } else {
            emit VerificationInvalid(_identity, topic);
            return false;
        }
    }

    function verificationIsValid(VerificationHolder _identity, uint256 topic)
        public
        view
        returns (bool verificationValid)
    {
        uint256 foundTopic;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;

        // Construct verificationId (identifier + verification type)
        bytes32 verificationId = keccak256(abi.encodePacked(trustedVerificationHolder, topic));

        // Fetch verification from user
        ( foundTopic, scheme, issuer, sig, data, ) = _identity.getVerification(verificationId);

        bytes32 dataHash = keccak256(abi.encodePacked(_identity, topic, data));
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));

        // Recover address of data signer
        address recovered = getRecoveredAddress(sig, prefixedHash);

        // Take hash of recovered address
        bytes32 hashedAddr = keccak256(abi.encodePacked(recovered));

        // Does the trusted identifier have they key which signed the user's verification?
        return trustedVerificationHolder.keyHasPurpose(hashedAddr, 3);
    }

    function getRecoveredAddress(bytes sig, bytes32 dataHash)
        public
        pure
        returns (address addr)
    {
        bytes32 ra;
        bytes32 sa;
        uint8 va;

        // Check the signature length
        if (sig.length != 65) {
            return (0);
        }

        // Divide the signature in r, s and v variables
        assembly {
            ra := mload(add(sig, 32))
            sa := mload(add(sig, 64))
            va := byte(0, mload(add(sig, 96)))
        }

        if (va < 27) {
            va += 27;
        }

        address recoveredAddress = ecrecover(dataHash, va, ra, sa);

        return (recoveredAddress);
    }

}
