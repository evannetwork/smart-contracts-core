# smart-contracts

## Next Version
### Features
### Fixes
### Deprecations

## Version 1.0.3
### Features
- add configurable output path
- add modified times check for files from additional paths
- add interface `MailBoxInterface` for interacting with global mailbox contract
- add test contracts `TestContract` and `TestContractFactory` for automatic testing
- add factory for `MultiSigWallet` contracts
- change call and answer storage formate in `ServiceContract.sol` to structs
- add more properties to result of `getCalls` and `getAnswers` in `ServiceContract.sol`

### Fixes
- remove `MultiSigWallet` dependency by copying `.sol` file into contracts folder, to prevent `npm install` issues, when used as a subdependency

### Deprecations
- deprecated rarely used (in edge-server) bin/compile.js


## Version 0.9.0
- initial version and release candidate for 1.0.0
