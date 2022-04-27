#!/bin/bash

# Creates and uploads the doctl tarballs for all arch and os.
# Requires the intended branch of doctl (typically feature/sandbox)
# to be checked out as a peer of this repo clone.

# Change these variables on changes to the space we are uploading to or naming conventions within it
TARGET_SPACE=do-serverless-tools
DO_ENDPOINT=nyc3.digitaloceanspaces.com
SPACE_URL="https://$TARGET_SPACE.$DO_ENDPOINT"

# Change this variable when local setup for s3 CLI access changes
AWS="aws --profile do --endpoint https://$DO_ENDPOINT"

# Define a test flag
if [ "$1" == "--test" ]; then
    PREFIX=doctl-test/
elif [ -n "$1" ]; then
    echo "Illegal argument"
    exit
fi

# Subroutine to tar and upload one doctl binary for mac or linux
function tar_and_upload() {
  echo "Making tarball for $1"
  rm -fr /tmp/sbx.tar.gz
  tar czf /tmp/sbx.tar.gz -C dist/doctl_$1 doctl
  echo "Uploading tarball for $1"
  $AWS s3 cp /tmp/sbx.tar.gz "s3://$TARGET_SPACE/${PREFIX}doctl-with-sandbox-$1.tar.gz"
  $AWS s3api put-object-acl --bucket "$TARGET_SPACE" --key "${PREFIX}doctl-with-sandbox-$1.tar.gz" --acl public-read
}

# Subroutine to zip and upload one doctl binary for windows
function zip_and_upload() {
  echo "Making zip file for $1"
  rm -fr /tmp/sbx.zip
  pushd dist/doctl_$1
  zip -r /tmp/sbx.zip doctl.exe
  popd
  echo "Uploading zip file for $1"
  $AWS s3 cp /tmp/sbx.zip "s3://$TARGET_SPACE/${PREFIX}doctl-with-sandbox-$1.zip"
  $AWS s3api put-object-acl --bucket "$TARGET_SPACE" --key "${PREFIX}doctl-with-sandbox-$1.zip" --acl public-read
}

# Orient
set -e
SELFDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SELFDIR/../../doctl

echo "Build all the binaries"
goreleaser build --rm-dist --snapshot

# Upload windows versions
for i in windows_386 windows_amd64 windows_arm64; do
  zip_and_upload $i
done  

# Upload other versions.  Note: although goreleaser builds linux_386
# we do not upload it because it won't correctly install a sandbox.
for i in darwin_amd64 darwin_arm64 linux_amd64 linux_arm64; do
  tar_and_upload $i
done  
