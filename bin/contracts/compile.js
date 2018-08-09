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

const { api, CLI } = require('actionhero')
const { promisify } = require('util')
const { unlink } = require('fs')

const Solc = require('../../lib/solc')


module.exports = class ContractsCompile extends CLI {
  constructor () {
    super()
    this.name = 'contracts compile'
    this.description = 'I compile all smart contracts'
    this.example = 'actionhero contracts compile'
  }

  inputs () {
    return { }
  }

  async run () {
    const solcLib = new Solc({
      api,
      config: api.config.eth,
      log: api.log,
    })
    const ensContracts = `${__dirname}/../../node_modules/ens/contracts`
    await promisify(unlink)(Solc.compiledPath)
    await promisify(unlink)(Solc.compiledJSPath)
    await solcLib.compileContracts(ensContracts)
  }
};
