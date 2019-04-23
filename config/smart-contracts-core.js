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

// but usually you want your project contracts to load
const projectContracts = '../../../build/contracts'

//  or in deployments, you want to load the contracts from the contracts directory
const deployedContracts = '../../../contracts'

exports['default'] = {
  smartContractsCore: () => {
    return {
      compileContracts: false,
      additionalPaths: [],
      // when a list is given, the contructor picks the first directory it finds contracts in,
      // if nothing is found it falls back to the smart-contracts-core contracts
      destinationPath: [projectContracts, deployedContracts]
    }
  }
}
