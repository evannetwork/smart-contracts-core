/*
  Copyright (C) 2018-present evan GmbH.

  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Affero General Public License, version 3,
  as published by the Free Software Foundation.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License along with this program.
  If not, see http://www.gnu.org/licenses/ or write to the

  Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA, 02110-1301 USA,

  or download the license from the following URL: https://evan.network/license/

  You can be released from the requirements of the GNU Affero General Public License
  by purchasing a commercial license.
  Buying such a license is mandatory as soon as you use this software or parts of it
  on other blockchains than evan.network.

  For more information, please contact evan GmbH at this address: https://evan.network/license/

*/

const smartContractsCore = require('../index')
const  Web3 = require('web3')
const Tx = require('ethereumjs-tx')


let account;
let key;
let gasPrice;
let gasLimit;
let solc = new smartContractsCore.Solc({
  config: { compileContracts: true, },
  log: console.log,
})

async function deployLibrary(_contractName, contracts, nonce) {
  const [ _, contractName ] = /:(.*)$/.exec(_contractName);
  const bytecode = contracts[contractName].bytecode

  const tra = {
    data: `0x${bytecode}`,
    from: account,
    gasLimit,
    gasPrice,
    nonce: `0x${nonce.toString(16)}`,
    value: 0,
  }

  const tx = new Tx(tra)
  tx.sign(key)

  const stx = tx.serialize()
  const web3 = new Web3(new Web3.providers.WebsocketProvider(
    process.env.CHAIN_ENDPOINT|| 'wss://testcore.evan.network/ws'))
  const result = await web3.eth.sendSignedTransaction('0x' + stx.toString('hex'))
  console.dir((({ contractAddress, gasUsed, status }) =>
    ({ contractName, contractAddress, gasUsed, status }))(result))
  return result.contractAddress
}

(async () => {
  console.group('compiling contracts')
  try {
    await solc.ensureCompiled()
    let contracts = await solc.getContracts(null, true)
    const toDeploys = solc.getLibrariesToRedeploy()
    if (toDeploys && toDeploys.length > 0) {
      console.log(`deploying: ${toDeploys.join(', ')}`)
      if (!process.env.ACCOUNTID || !process.env.PRIVATEKEY) {
        throw Error('ACCOUNTID or PRIVATEKEY unset, set both as environment variables')
      }

      account = process.env.ACCOUNTID
      key = new Buffer(process.env.PRIVATEKEY, 'hex')
      gasPrice = process.env.GASPRICE || '0x2e90edd000'  // 200GWei
      gasLimit = '0x7a1200'  // 8000000
      const libraryUpdates = {}
      const web3 = new Web3(new Web3.providers.WebsocketProvider(
        process.env.RPC_WEBSOCKET || 'wss://testcore.evan.network/ws'))
      let nonce = await web3.eth.getTransactionCount(account)
      for (let toDeploy of toDeploys) {
        // deploy contract
        const deployed = await deployLibrary(toDeploy, contracts, nonce++)
        // update compiled contracts
        const toLink = { [toDeploy]: deployed }
        solc.linkLibraries(contracts, toLink)
        Object.assign(libraryUpdates, toLink)
        // re-compile contracts and update compiled files
        await solc.ensureCompiled()
        contracts = await solc.getContracts(null, true)
        // (if required, repeat until all contracts have been included in contracts file)
      }
      console.log('deployed new libraries, make sure to update config accordingly')
      console.dir(libraryUpdates)
    }
  } catch(ex) {
    console.dir(ex)
    console.error(`building contracts failed: ${ex.msg || ex}${ex.stack ? '; ' + ex.stack : ''}`)
  }
  console.groupEnd('compiling contracts')
  console.log('done')
})()
