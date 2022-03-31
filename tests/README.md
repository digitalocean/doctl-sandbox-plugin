## Functional Tests for Doctl Sandbox

This directory is the doctl sandbox counterpart of the `tests` directory in the `nimbella-cli`repo.  It contains tests relevant to the doctl sandbox plugin, which incorporates the Nimbella CLI in library form.usage by DigitalOcean.  It uses the [bats](https://github.com/bats-core/bats-core) shell script testing tool to run sample commands against the current namespace and checks the results.  _Warning: use a current namespace that does not contain valuable information._

### Running the tests

- Install the `bats` tool and supporting plugins:

```
npm install
```

- Run the following command.

```
npm test
```

For more details see the counterpart `README.md` in the `tests` directory of the `nimbella-cli` repo.
