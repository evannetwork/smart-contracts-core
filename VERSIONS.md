# smart-contracts-core

## Next Version
### Features
- add `PayableRegistrar`, that allows to by domain names with EVEs for limited time frames
- add `TimedENS`, that allows to register domains for limited time frames

### Fixes
### Deprecations


## Version 1.3.0
### Features
- add description to claims
- add `addClaimWithMetadata` function to claims for setting claim and metadata at the same time
- add creation block data to claim information
- claims are not overwritten anymore, but a new claim is created per set call
- add `Congress.sol` for holding votes on-chain

### Fixes
### Deprecations


## Version 1.2.0
### Features
- add ERC725/735 compliant Claims and Identity contracts
- include bytecode within compiled.js files for `claims/OriginIdentity.sol:OriginIdentity`
- add `TicketVendorInterface`

### Deprecations
- use solc 0.4.24 as compiler version
- contracts have been updated accordingly to match solc 0.4.24
- make compiler versions upward compatible (`^solc 0.4.24`)


## Version 1.1.3
### Features
- add permissions to `TestDataContractFactory` for additional test for user management

### Fixes
- fix `setUserRole` issue in `DSRolesPerContract`, that could produce invalid user indices when removing accounts from roles


## Version 1.1.2
### Fixes
- fix destinationPath handling for cases when output file doesn't exist
- fix `removeContractMember`
- add `dst` argument to contract compile functions
- add provider (owner of new `BaseContract`) as a consumer to internal mappings, that reflect this state


## Version 1.1.1
### Fixes
- use `keccak256` instead of `sha3` for hashing
- add `dst` argument to `lib/solc.js` functions to bypass config for destination path
- add support for removing contract members the same way as inviting them


## Version 1.1.0
### Fixes
- update hasing to `keccak256`
- add `registerFactory(address factoryId)` to `BusinessCenterInterface`
- add matching auth checks


## Version 1.0.3
### Features
- add configurable output path
- add modified times check for files from additional paths
- add interface `MailBoxInterface` for interacting with global mailbox contract
- add test contracts `TestContract` and `TestContractFactory` for automatic testing
- add factory for `MultiSigWallet` contracts
- change call and answer storage formate in `ServiceContract.sol` to structs
- add more properties to result of `getCalls` and `getAnswers` in `ServiceContract.sol`
- add `registerFactory(address factoryId)` to `BusinessCenterInterface`

### Fixes
- remove `MultiSigWallet` dependency by copying `.sol` file into contracts folder, to prevent `npm install` issues, when used as a subdependency
- add cloning for config option in Solc module to avoid side effects

### Deprecations
- deprecated rarely used (in edge-server) bin/compile.js


## Version 0.9.0
- initial version and release candidate for 1.0.0
