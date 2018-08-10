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

// default paths
const solPath = `../contracts`
const compiledPath = `${__dirname}/${solPath}`

const compiledFile = 'compiled.json'
const compiledJSFile = 'compiled.js'

class Solc {
  constructor(options) {
    this.log = options.log;
    this.config = options.config;

    // when using the constructor it is possible to search for the best preset destiantionPath
    // the directory must exist, or the default is used
    if(!this.config.destinationPath ||
       typeof this.config.destinationPath === 'string' &&
       !fs.existsSync(path.resolve( this.config.destinationPath, compiledFile)))
      this.config.destinationPath = compiledPath
    else if(Array.isArray(this.config.destinationPath)) {
      this.config.destinationPath.push(compiledPath)
      for(let d of this.config.destinationPath)
        if(fs.existsSync(path.resolve( d, compiledFile))) {
          this.config.destinationPath = d
          break;
        }
    }
    this.log(`destinationPath: ${this.config.destinationPath}`)
  }

  async writeContractsToFile(contracts) {
    
    let fn = 'fn' 
    let jsfn = 'jsfn'
    const content = JSON.stringify(contracts)
    // remove bytecode from frontend file
    Object.keys(contracts).forEach((key) => { delete contracts[key].bytecode })
    
    // write contracts file into an seperated javascript file to be able to include it 
    // into a systemjs build
    const jscontent = `(function (root, factory) {
        if (typeof define === 'function' && define.amd) {
            define([], factory);
        } else if (typeof module === 'object' && module.exports) {
            module.exports = factory();
        } else {
          root.returnExports = factory();
        }
      }(typeof self !== 'undefined' ? self : this, function () {
        return ${JSON.stringify(contracts)};
      }));`
    if (this.config.destinationPath) {
      const fn = path.resolve( this.config.destinationPath, compiledFile)
      const jsfn = path.resolve( this.config.destinationPath, compiledJSFile)
      if (!fs.existsSync(this.config.destinationPath)) fs.mkdirSync(this.config.destinationPath)
      await Promise.all( [ promisify(fs.writeFile)( fn, content),
                           promisify(fs.writeFile)(jsfn, jscontent) ])
                           
    }
    return { fn: content, jsfn: jscontent }
  }

  async compileContracts(src_tree) {
    this.log('Compile Solidity contracts...')
    const solFiles = {}
    
    for(let dir in src_tree)
      for(let f of src_tree[dir])
        if (f.toLowerCase().endsWith('.sol')) {
          if(f in solFiles) console.info(f, " is duplicate filename")
          solFiles[f] = (promisify(fs.readFile)(path.resolve(dir, f), 'utf8'));
        }

    await Promise.all(Object.values(solFiles))

    for(let f in solFiles) solFiles[f] = await solFiles[f]
    
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

  // when passing a destinationPath here, it must be a single path, it doesn't need to exist
  // it will be created
  async ensureCompiled(additionalPaths = [], dst) {
    this.config.destinationPath = dst || this.config.destinationPath
    const ofile = path.resolve( this.config.destinationPath, compiledFile )
    const compiled = fs.existsSync(ofile)
    if (!(this.config.compileContracts || !compiled)) return

    // backup original runtime path to recover it
    const originalRuntimePath = process.cwd();

    // switch process dir to the current directory to handle correct node_module paths, when the
    // smart-contracts-core project was linked, too
    process.chdir(path.resolve(__dirname))

    const core_src = [solPath,
                      findup('node_modules')+'/ens/contracts',
                     ].map(modulePath => path.resolve(__dirname, modulePath))

    additionalPaths = Array.isArray(additionalPaths) ? additionalPaths : [additionalPaths]

    // navigate to the original runtime folder to prevent side effects
    process.chdir(path.resolve(originalRuntimePath))
    
    // having additional paths later allows you to overwrite core contracts if needed
    const src_dirs = core_src.concat(additionalPaths)
    const src_files = src_dirs.map( d => rread(d).map(f =>  f.replace('\\', '/') ))
    const src_tree = {}
    for(let i in src_dirs) src_tree[src_dirs[i]] = src_files[i]
    
    // if no compile exists, do one
    if(!compiled) return await this.compileContracts(src_tree)

    // check file dates if anything newer than previous compile
    // also, only check the additional paths, the core contracts don't change
    const ostat = fs.statSync(ofile)
    const stats = additionalPaths.map( d => src_tree[d].map(
      f => promisify(fs.stat)(path.resolve(d, f))
        .then((s) => { if (s.mtimeMs > ostat.mtimeMs) throw f; else return true; } )))

    return await Promise.all(stats.reduce((i,a) => a.concat(i) ,[]))
      .then(() => this.log('nothing to compile'))
      .catch((f) => { this.log(f, ' changed, Recompile all ...'); return this.compileContracts(src_tree); } )

  }

  getContracts() {
    const contracts = require(path.resolve(this.config.destinationPath, compiledFile))
    const shortenedContracts = {}
    Object.keys(contracts).forEach((key) => {
      const contractKey = (key.indexOf(':') !== -1) ? key.split(':')[1] : key
      shortenedContracts[contractKey] = contracts[key]
    })
    return shortenedContracts
  }
}

module.exports = Solc
