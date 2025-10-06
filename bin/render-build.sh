#!/usr/bin/env bash
set -o errexit

sudo apt-get update -y
sudo apt-get install -y --no-install-recommends libgeos-dev

bundle install --without development test
yarn install --frozen-lockfile
bundle exec rails assets:precompile
