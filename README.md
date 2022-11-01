# doctl-sandbox-plugin
Supports certain `doctl serverless` subcommands by incorporating the DigitalOcean Functions Deployer via a plugin (called "the sandbox plugin" for historical reasons).  The deployer is written in TypeScript and runs in its own subprocess.  The supported commands are

- `doctl serverless deploy`
- `doctl serverless watch`
- `doctl serverless get-metadata`

All other `doctl serverless` subcommands are now implemented natively without the use of the plugin (and the `get-metadata` and `watch` commands may follow soon).

## What's here

The source code of the plugin itself is tiny and comprises the Typescript source in `src`, and supporting material in `package*.json` and `tsconfig.json`.  Building this source creates a much larger artifact since it will incorporate a version of `@digitalocean/functions-ddeployer` as a dependency.

The repo also includes GitHub workflows and supporting scripts to maintain the sandbox plugin in its download site and to run the serverless e2e tests using a committed `doctl` version, denoted by a repository (default `doctl`) and a branch (default `main`).

## How to do Typical Changes

### Incorporate a new version of the deployer

This is probably the most common change, given how little code there is in the plugin.  Run the script

```
./new-deployer.sh <version>
```
for example

```
./new-deployer.sh 5.0.3
```

The version is a necessary argument for now since there is no "current version" being maintained (this is easily fixed).  The result is to bring the `functions-deployer` dependency up-to-date locally (this script does not commit the result).

At this point, you should have changes to `package.json` and `package-lock.json`.  Commit and push these changes.  The GitHub workflow should fire and build a new sandbox tarball in the download area.  This download will _not_ be used by `doctl` until the minimum sandbox plugin version is changed there.

### Changes to the plugin source itself

The TypeScript code in the plugin does some impedence matching between `doctl` and the deployer, which was originally designed to work with `nim` and changes to it are occasionally needed.   These can be managed by the usual process of opening and merging PRs.  Until the plugin version number is incremented via `npm version [major|minor|patch]`, these changes will not be visible outside this repo.  When a change to the plugin version is committed and pushed, a new download will be produced.

### Testing new plugin code

Once there is a new plugin version, it can be tested prior to its appearance in any release of `doctl`.   To do this

1.  Create a branch in `doctl` or a fork thereof where the `minSandboxVersion` constant in `commands/sandbox.go` has been incremented to match the new version.  This could be a PR or just a branch.
2.  In the GitHub UI for this repo, select `Actions`, then `Test Doctl Sandbox` on the left.
3.  A dropdown labelled `Run Workflow` should appear.  In this dropdown, fill in `Repository to Test` and `Branch to Test`, then press `Run Workflow`.
4.  Assuming tests pass and you want to make this change permanant, open a PR using the branch from step (1) if you haven't already.  When that PR merges, the change will be active.
