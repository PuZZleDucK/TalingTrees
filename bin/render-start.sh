#!/usr/bin/env bash
set -euo pipefail

bundle exec rails db:migrate
bundle exec rails server -p "${PORT:-10000}" -b 0.0.0.0
