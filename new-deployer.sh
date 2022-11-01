#!/bin/bash

# Updates to a specific deployer release
# Currently, we are using https dependencies for the deployer because we are,
# at least temporarily, not publishing in npm.

if [ -z "$1" ]; then
		echo "A version argument is required."
		exit 1
fi

set -e
rm -fr node_modules package-lock.json
npm install https://do-serverless-tools.nyc3.digitaloceanspaces.com/digitalocean-functions-deployer-$1.tgz --save-exact
npm install
