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

import "./AbstractENS.sol";
import "./AbstractPublicResolver.sol";


contract EnsReader {
    // AbstractENS ens = AbstractENS($ENS_ADDRESS);
    AbstractENS ens = AbstractENS(0xd9b054d2FFA8Cf301885Af53db86971881E2EA54);
    // bytes32 rootDomain = $NAMEHASH_ROOT_DOMAIN;
    // evan: 0x01713a3bd6dccc828bbc37b3f42f3bc5555b16438783fabea9faf8c2243a0370
    // test: 0x04f740db81dc36c853ab4205bddd785f46e79ccedca351fc6dfcbd8cc9a33dd6
    bytes32 rootDomain = 0x01713a3bd6dccc828bbc37b3f42f3bc5555b16438783fabea9faf8c2243a0370;

    function getAddr(bytes32 node) constant public returns (address) {
        return AbstractPublicResolver(ens.resolver(keccak256(abi.encodePacked(rootDomain, node))))
            .addr(keccak256(abi.encodePacked(rootDomain, node)));
    }

    function setEns(address ensAddress) internal {
        ens = AbstractENS(ensAddress);
    }
}
