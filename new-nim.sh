#!/bin/bash

# Updates to the latest 'nim' and deployer

rm -fr node_modules package-lock.json
npm install @nimbella/nimbella-cli@latest --save-exact
npm install @nimbella/nimbella-deployer@latest --save-exact
npm install
npx patch-package @nimbella/nimbella-cli
