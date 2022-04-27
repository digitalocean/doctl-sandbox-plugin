#!/usr/bin/env bash

set -e
SELFDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SELFDIR/../../doctl

export GOFLAGS=-mod=vendor
export GO111MODULE=on
export CGO_ENABLED=0
cd cmd/doctl && go build -o ../../builds/
