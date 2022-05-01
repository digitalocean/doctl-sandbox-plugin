#!/bin/bash

# Creates and uploads the 'fat tarball' for `doctl sandbox install`

# Change these variables on changes to the space we are uploading to or naming conventions within it
TARGET_SPACE=do-serverless-tools
DO_ENDPOINT=nyc3.digitaloceanspaces.com
SPACE_URL="https://$TARGET_SPACE.$DO_ENDPOINT"
TARBALL_NAME_PREFIX="doctl-sandbox"
TARBALL_NAME_SUFFIX="tar.gz"

# Change this variable when local setup for s3 CLI access changes
AWS="aws --profile do --endpoint https://$DO_ENDPOINT"

# Define a test flag
if [ "$1" == "--test" ]; then
		TESTING=true
elif [ -n "$1" ]; then
		echo "Illegal argument"
		exit
fi

# Orient
SELFDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SELFDIR

echo "Determining the new (?) version"
SANDBOX_VERSION=$(jq -r .version < package.json)
NIM_VERSION=$(jq -r '.dependencies|."@nimbella/nimbella-cli"' < package.json)
VERSION="$NIM_VERSION-$SANDBOX_VERSION"
echo "New version is $VERSION"
TARBALL_NAME="$TARBALL_NAME_PREFIX-$VERSION.$TARBALL_NAME_SUFFIX"
echo "New tarball name is $TARBALL_NAME"

if [ -z "$TESTING" ]; then
  echo "Checking whether the new (?) tarball is already uploaded"
  UPLOADED=$($AWS s3api head-object --bucket "$TARGET_SPACE" --key "$TARBALL_NAME")
  if [ "$?" == "0" ]; then
    echo "$TARBALL_NAME has already been built and uploaded.  Skipping remaining steps."
    exit 0
  fi
else
  echo "Only testing, skipping upload check"
fi

set -e

echo "Removing old artifacts"
rm -rf sandbox *.tar.gz

echo "Ensuring a full install"
npm install

echo "Building the code"
npx tsc

# For testing we symlink the "real" sandbox as viewed by the local doctl
# Otherwise, we make a sandbox folder for staging the upload
if [ -n "$TESTING" ]; then
		echo "Linking the local sandbox for provisioning"
		ln -s "$HOME/Library/Application Support/doctl/sandbox" .
		echo "Removing former node_modules"
		rm -fr sandbox/node_modules
else
		echo "Making sandbox folder for staging"
    mkdir sandbox
fi

echo "Moving artifacts to the sandbox folder"
cp lib/index.js sandbox/sandbox.js
cp -r node_modules sandbox
echo "$VERSION" > sandbox/version

if [ -n "$TESTING" ]; then
		echo "Test setup complete"
		rm sandbox
		exit
fi

echo "Making the tarball"
tar czf "$TARBALL_NAME" sandbox

echo "Uploading"
$AWS s3 cp "$TARBALL_NAME" "s3://$TARGET_SPACE/$TARBALL_NAME"
$AWS s3api put-object-acl --bucket "$TARGET_SPACE" --key "$TARBALL_NAME" --acl public-read
