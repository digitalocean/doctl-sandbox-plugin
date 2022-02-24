#!/bin/bash
#
# DigitalOcean, LLC CONFIDENTIAL
# ------------------------------
#
#   2021 - present DigitalOcean, LLC
#   All Rights Reserved.
#
# NOTICE:
#
# All information contained herein is, and remains the property of
# DigitalOcean, LLC and its suppliers, if any.  The intellectual and technical
# concepts contained herein are proprietary to DigitalOcean, LLC and its
# suppliers and may be covered by U.S. and Foreign Patents, patents
# in process, and are protected by trade secret or copyright law.
#
# Dissemination of this information or reproduction of this material
# is strictly forbidden unless prior written permission is obtained
# from DigitalOcean, LLC.

# Creates and uploads the doctl tarball for mac and linux
# Requires that the prototype branch of doctl be checked out as a peer of this repo clone

# Change these variables on changes to the space we are uploading to or naming conventions within it
TARGET_SPACE=do-serverless-tools
DO_ENDPOINT=nyc3.digitaloceanspaces.com
SPACE_URL="https://$TARGET_SPACE.$DO_ENDPOINT"

# Change this variable when local setup for s3 CLI access changes
AWS="aws --profile do --endpoint https://$DO_ENDPOINT"

# Orient
set -e
SELFDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SELFDIR/../../doctl

echo "Removing old artifacts"
rm -rf *.tar.gz

echo "Building the darwin binary"
GOOS=darwin scripts/_build.sh
cd builds && rm -fr darwin && mkdir darwin && mv doctl_darwin* darwin/doctl && cd ..

echo "Building the linux binary"
GOOS=linux scripts/_build.sh
cd builds && rm -fr linux && mkdir linux && mv doctl_linux* linux/doctl && cd ..

echo "Making the tarballs"
tar czf doctl-sandbox-mac.tar.gz -C builds/darwin doctl
tar czf doctl-sandbox-linux.tar.gz -C builds/linux doctl

echo "Uploading"
$AWS s3 cp doctl-sandbox-mac.tar.gz "s3://$TARGET_SPACE/doctl-with-sandbox-mac.tar.gz"
$AWS s3api put-object-acl --bucket "$TARGET_SPACE" --key "doctl-with-sandbox-mac.tar.gz" --acl public-read
$AWS s3 cp doctl-sandbox-linux.tar.gz "s3://$TARGET_SPACE/doctl-with-sandbox-linux.tar.gz"
$AWS s3api put-object-acl --bucket "$TARGET_SPACE" --key "doctl-with-sandbox-linux.tar.gz" --acl public-read
