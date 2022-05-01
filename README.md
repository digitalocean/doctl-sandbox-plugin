# doctl-sandbox-plugin
Supports the `doctl sandbox` (alias `sbx`, `serverless` or `sls`) subcommand by incorporating parts of the Nimbella CLI via a plugin.

## What's here

The source code of the plugin itself is tiny and comprises the Typescript source in `src`, some necessary patches to dependencies in `patches`, and supporting material in `package*.json` and `tsconfig.json`.  Building this source creates a much larger artifact since it will incorporate a version of `@nimbella/nimbella-cli` as a dependency.

The repo also includes GitHub workflows and supporting scripts to maintain the sandbox plugin in its download site and to run the sandbox e2e tests using a committed `doctl` version, denoted by a repository (default `doctl`) and a branch (default `main`).

## How to do Typical Changes

### Incorporate a new version of `nim`

This is probably the most common change, given how little code there is in the plugin.  Run the script

```
./new-nim.sh
```

to bring the `nimbella-cli` and `nimbella-deployer` dependencies up-to-date locally (this script does not commit the result).

The final step of the script attempts to update a needed (for now) patch to `nimbella-cli`.  The success of this step can depend on what has changed in `nim` since the last time.   A successful run will end with (something like)

```
✔ Created file patches/@nimbella+nimbella-cli+3.0.10.patch
💡 @nimbella/nimbella-cli is on GitHub! To draft an issue based on your patch run
    npx patch-package @nimbella/nimbella-cli --create-issue
```

A failure will contain a message like

```
**ERROR** Failed to apply patch for package @nimbella/nimbella-cli at path


    node_modules/@nimbella/nimbella-cli
```

and will end with

```
⁉️  Not creating patch file for package '@nimbella/nimbella-cli'
⁉️  There don't appear to be any changes.
```

To recover from this error:
1.  Edit the file at `node_modules/@nimbella/nimbella-cli/lib/NimBaseCommand.js` (it is minified and hard to read).
2.  Find the substring `setNamespaceHeaderOmission(!0)` and change it to `setNamespaceHeaderOmission(0)`.  There should be only one occurrence.
3.  If the editor you used leaves temp or backup files behind, be sure to delete them.
4.  In the root of the repo clone, run `npx patch-package @nimbella/nimbella-cli`

At this point, you should have changes to `package.json`, `package-lock.json`, and the files in the `patches` folder.  Commit and push these changes.  The GitHub workflow should fire and build a new sandbox tarball in the download area.  This download will _not_ be used by `doctl` until the minimum sandbox plugin version is changed there.

### Changes to the plugin source itself

The TypeScript code in the plugin does some impedence matching between `doctl` and `nim` and changes to it are occasionally needed.   These can be managed by the usual process of opening and merging PRs.  Until the sandbox version number is incremented via `npm version [major|minor|patch]`, these changes will not be visible outside this repo.  When a change to the sandbox version is committed and pushed, a new download will be produced.

### Testing new sandbox code

Once there is a new sandbox version, it can be tested prior to its appearance in any release of `doctl`.   To do this
1.  Create a branch in `doctl` or a fork thereof where the `minSandboxVersion` constant in `commands/sandbox.go` has been incremented to match the new version.  This could be a PR or just a branch.
2.  In the GitHub UI for this repo, select `Actions`, then `Test Doctl Sandbox` on the left.
3.  A dropdown labelled `Run Workflow` should appear.  In this dropdown, fill in `Repository to Test` and `Branch to Test`, then press `Run Workflow`.
4.  Assuming tests pass and you want to make this change permanant, open a PR using the branch from step (1) if you haven't already.  When that PR merges, the change will be active.
