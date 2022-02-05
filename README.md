# doctl-sandbox-plugin
Supports a new `doctl` subcommand by incorporating parts of the Nimbella CLI

## What's here

The source code of the plugin itself is tiny and comprises the Typescript source in `src`, some necessary patches to dependencies in `patches`, and supporting material in `package*.json` and `tsconfig.json`.  Building this source creates a much larger artifact since it will incorporate a version of `@nimbella/nimbella-cli` as a dependency.

The script `package.sh` will build, package, and upload the plugin (versions for `linux` and `mac` currently) to a known object in a known `s3` bucket.  The destination can be edited by changing declarations near the top of the script.

The JavaScript "shell" script `generateCobraWrappers.js` and the contents of `doctl-extras` and `nimbella-cli-extras` comprise a codegen capability that can be used to jump start additions to the planned `doctl` command by translating material in an `oclif` manifest.  The moving parts are not yet unified by a script.  Better scripting and documentation will be added when it next becomes helpful to use this capability.
