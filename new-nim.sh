#!/bin/bash

# Updates to the latest 'nim' and deployer

npm install @nimbella/nimbella-cli@latest --save-exact
npm install @nimbella/nimbella-deployer@latest --save-exact
npx patch-package @nimbella/nimbella-cli
