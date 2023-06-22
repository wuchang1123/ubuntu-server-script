#!/bin/bash

TAILSCALE_AUTHKEY=$1
HOSTNAME=$2

curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname=$HOSTNAME --advertise-exit-node
