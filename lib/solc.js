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

const {promisify} = require('util')
const fs = require('fs')
const rread = require('fs-readdir-recursive')
const solc = require('solc')
const path = require('path')
const findup = require('findup-sync')

const errorPattern = /^.*error:/i;
const filenamePattern = /^([^:]+)(?:\s|.)*$/;


class Solc {
  constructor(options) {
    this.log = options.log;
    this.config = options.config;
  }

  async writeContractsToFile(contracts) {
    if (!fs.existsSync(Solc.solPath)) {
      fs.mkdirSync(Solc.solPath)
    }
    await promisify(fs.writeFile)(Solc.compiledPath, JSON.stringify(contracts))
    // remove bytecode from frontend file
    Object.keys(contracts).forEach((key) => { delete contracts[key].bytecode })
    // write contracts file into an seperated javascript file to be able to include it 
    // into a systemjs build
    await promisify(fs.writeFile)(Solc.compiledJSPath, `
      (function (root, factory) {
        if (typeof define === 'function' && define.amd) {
            define([], factory);
        } else if (typeof module === 'object' && module.exports) {
            module.exports = factory();
        } else {
          root.returnExports = factory();
        }
      }(typeof self !== 'undefined' ? self : this, function () {
        return ${JSON.stringify(contracts)};
      }));
    `);
  }

  async compileContracts(additionalPath) {
    this.log('Compile Solidity contracts...')
    const solFiles = {}
    let files = rread(Solc.solPath)
    files = files.map((file) => file.replace('\\', '/'));
    for (let file of files) {
      if (file.toLowerCase().endsWith('.sol')) {
        solFiles[file] = await (promisify(fs.readFile)(`${Solc.solPath}/${file}`, 'utf8'))
      }
    }
    // add ENS files
    const resolvedPath = `${findup('node_modules')}/ens/contracts`;
    const ensFiles = await promisify(fs.readdir)(resolvedPath)
    for (let file of ensFiles) {
      if (file.toLowerCase().endsWith('.sol')) {
        solFiles[file] = await (promisify(fs.readFile)(`${resolvedPath}/${file}`, 'utf8'))
      }
    }
    if(additionalPath) {
      const pathsToLoad = Array.isArray(additionalPath) ? additionalPath : [additionalPath]
      for (let pathToLoad of pathsToLoad) {
        const resolvedPath = path.resolve(__dirname, pathToLoad)
        const files = await promisify(fs.readdir)(resolvedPath)
        for (let file of files) {
          if (file.toLowerCase().endsWith('.sol')) {
            solFiles[file] = await (promisify(fs.readFile)(`${resolvedPath}/${file}`, 'utf8'))
          }
        }
      }
    }

    const output = solc.compile({ sources: solFiles, }, 1) // 1 activates the optimizer
    // drop warnings
    const errors = output.errors ? output.errors.filter(line => errorPattern.test(line)) : null;
    if (errors && errors.length) {
      this.log('Contract compile error: \n' + errors, 'error')
      process.exit(1)
    } else if (output.errors) {
      const warnings = {};
      output.errors.forEach((warning) => {
        const filename = warning.replace(filenamePattern, '$1');
        if (!warnings[filename]) {
          warnings[filename] = 1;
        } else {
          warnings[filename]++;
        }
      });
      this.log(`warnings per file: ${JSON.stringify(warnings, null, 2)}`);
    }
    const trimmed = {}
    Object.keys(output.contracts).forEach((key) => {
      trimmed[key] = {
        interface: output.contracts[key].interface,
        bytecode: output.contracts[key].bytecode,
      }
    })
    return this.writeContractsToFile(trimmed)
  }

  async ensureCompiled(additionalPath) {
    const alreadyCompiled = fs.existsSync(Solc.compiledPath)
    if (this.config.compileContracts || !alreadyCompiled) {
      await this.compileContracts(additionalPath)
    }
  }

  getContracts() {
    const contracts = require(Solc.compiledPath)
    const shortenedContracts = {}
    Object.keys(contracts).forEach((key) => {
      const contractKey = (key.indexOf(':') !== -1) ? key.split(':')[1] : key
      shortenedContracts[contractKey] = contracts[key]
    })
    return shortenedContracts
  }
}
Solc.solPath = `${__dirname}/../contracts`
Solc.compiledPath = `${Solc.solPath}/compiled.json`
Solc.compiledJSPath = `${Solc.solPath}/compiled.js`

module.exports = Solc