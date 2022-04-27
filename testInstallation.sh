#!/bin/bash

# Tests the 'sbx install', 'sbx connect' and 'sbx upgrade' commands.
# Sets things up for testing additional commands using the 'bats' tests.
# Designed to run in a GitHub action.

# Assumes a local doctl build and that the 'doctl' repo clone is cwd
if ! [ -f "builds/doctl" ]; then
  echo "Doctl not built or wrong current directory"
  exit 1
fi
set -e

DOCTL=builds/doctl

# Determine the OS and use that to determine where the sandbox installation will be located.
# On windows we assume we are running under the git bash shell (which is what GitHub actions
# use when you specify shell: bash).
UOS=$(uname -s)
if [[ "$UOS" == *Linux* ]]; then
  SANDBOX="$HOME/.config/doctl/sandbox"
elif [ "$UOS" == Darwin ]; then
  SANDBOX="$HOME/Library/Application Support/doctl/sandbox"
else
  # Assume otherwise windows
  SANDBOX="$APPDATA/doctl/sandbox"
fi

$DOCTL sbx install
$DOCTL sbx connect
rm "$SANDBOX/version"
$DOCTL sbx upgrade
