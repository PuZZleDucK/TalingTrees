#!/usr/bin/env bash
set -o errexit

mkdir -p bin/tailscale
TS_VER=1.84.0
curl -fsSL https://pkgs.tailscale.com/stable/tailscale_${TS_VER}_amd64.tgz \
 | tar -xz --strip-components=1 -C bin/tailscale

bundle install --without development test
yarn install --frozen-lockfile
bundle exec rails assets:precompile
