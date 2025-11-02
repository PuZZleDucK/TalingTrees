#!/usr/bin/env bash
set -euo pipefail



export PATH="$PWD/bin/tailscale:$PATH"
mkdir -p /data || true
mkdir -p tmp/tailscaled

# 1) Run tailscaled in userspace, expose a local SOCKS5 proxy
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --state=/data/tailscaled.state &

sleep 2

# 2) Join tailnet - Advertise the Render service so peers can find us.
TAILSCALE_HOSTNAME="srv-d3hq6i49c44c73c9k1rg-68db68f786-cdgsn"
tailscale up --authkey "$TS_AUTHKEY" --hostname "$TAILSCALE_HOSTNAME" --accept-dns=false

# 3a) If your outbound deps are HTTP/HTTPS: route them via SOCKS
export ALL_PROXY="socks5://localhost:1055"
export HTTPS_PROXY="$ALL_PROXY" HTTP_PROXY="$ALL_PROXY"

# 4) Rails
bundle exec rails db:migrate
bundle exec rails server -p "${PORT:-10000}" -b 0.0.0.0
