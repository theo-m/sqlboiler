#!/usr/bin/env sh

set -ex

./boil.sh build
ln -sf "$(pwd)"/sqlboiler      "$GOPATH"/bin

./boil.sh build psql
ln -sf "$(pwd)"/sqlboiler-psql "$GOPATH"/bin
