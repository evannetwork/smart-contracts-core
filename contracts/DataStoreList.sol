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

pragma solidity ^0.4.0;

import "./Core.sol";

contract DataStoreList is Owned {
    uint public length;
    uint public lastModified;
    mapping(uint => bytes32) data;

    function add(bytes32 value) only_owner {
        uint index = length++;
        data[index] = value;
        lastModified = now;
    }

    function remove(uint index) only_owner {
        var lastIndex = --length;
        if (lastIndex != 0) {
            data[index] = data[lastIndex];
        }
        delete data[lastIndex];
        lastModified = now;
    }

    function update(uint index, bytes32 value) only_owner {
        assert(index <= length);
        data[index] = value;
        lastModified = now;
    }

    function get(uint index) constant returns(bytes32) {
        return data[index];
    }

    function indexOf(bytes32 value) constant returns(uint index, bool okay) {
        okay = false;
        for (uint256 i = 0; i < length; i++) {
            if (data[i] == value) {
                index = i;
                okay = true;
                break;
            }
        }
    }

}
