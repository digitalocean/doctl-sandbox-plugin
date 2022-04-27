#!/bin/bash

# Obtains the correct doctl for the os and arch of the machine it is running on.
# Intended for e2e sandbox plugin testing.  Assumes running under bash even on windows.
# Note: once there is sandbox support in official doctl releases, this should download
# those releases.  Currently, downloads from the beta staging area.

# Requires the staging directory as an argument.
# Places doctl in the 'bin' subdirectory thereof.
if [ -z "$1" ]; then
  echo "Missing argument"
  exit 1
elif [ -n "$2" ]; then
  echo "Too many arguments"
  exit 1
fi

# The following is heuristic and incomplete.  A better way would be welcome.
which uname > /dev/null || (echo "Cannot run on native windows" && exit 1)
set -e
UNPACK="tar xzf"
SUFFIX="tar.gz"
UOS=$(uname -s)
if [[ "$UOS" == *Linux* ]]; then
  OS=linux
elif [ "$UOS" == Darwin ]; then
  OS=darwin
else
  OS=windows
  UNPACK=unzip
  SUFFIX=zip
fi
UARCH=$(uname -m)
if [ $UARCH == x86_64 ]; then
  ARCH=amd64
elif [[ $UARCH == *386* ]]; then
  ARCH=386
else
  ARCH=$UARCH
fi
DOWNLOAD="https://do-serverless-tools.nyc3.digitaloceanspaces.com/doctl-with-sandbox-${OS}_${ARCH}.$SUFFIX"
echo "OS=$OS, ARCH=$ARCH"
echo "Downloading from $DOWNLOAD"

# Do the download
cd "$1"
[ -d bin ] || mkdir bin
curl "$DOWNLOAD" -o "doctl.$SUFFIX"
cd bin
$UNPACK "../doctl.$SUFFIX"
rm "../doctl.$SUFFIX"
echo "Doctl with sandbox has been downloaded to $1/bin"
