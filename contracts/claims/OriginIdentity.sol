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

import "./ClaimHolder.sol";

// This will be deployed exactly once and represents Origin Protocol's
// own identity for use in signing attestations.


contract OriginIdentity is ClaimHolder {
	uint public VERSION_ID;
	
    constructor() public {
        VERSION_ID = 2;
    }
}
