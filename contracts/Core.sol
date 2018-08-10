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

// empty contract for keeping filename -> contract name behavior
contract Core {}

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) only_owner {
        owner = newOwner;
    }

    // This only allows the owner to perform function
    modifier only_owner {
      assert(msg.sender == owner);
      _;
    }
}

contract OwnedMortal is Owned {
    function kill() only_owner {
        suicide(owner);
    }
}

contract OwnedModerated is Owned {
    mapping(address => bool) public moderators;

    function addModerator(address newModerator) only_owner {
        moderators[newModerator] = true;
    }

    function removeModerator(address newModerator) only_owner {
        delete moderators[newModerator];
    }

    function removeModeratorship() only_owner_or_moderator {
        delete moderators[msg.sender];
    }

    function transferModeratorship(address newModerator) only_owner_or_moderator {
        delete moderators[msg.sender];
        moderators[newModerator] = true;
    }

    // This only allows moderator to perform function
    modifier only_owner_or_moderator {
      assert(msg.sender == owner || moderators[msg.sender]);
      _;
    }
}
