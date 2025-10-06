#!/usr/bin/env bash
set -o errexit

bundle install --without development test
yarn install --frozen-lockfile
bundle exec rails assets:precompile
