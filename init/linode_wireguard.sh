#!/bin/bash
URL_PREFIX=https://raw.githubusercontent.com/wuchang1123/ubuntu-server-script/main

LINODE_LISHUSERNAME=
USER_NAME=
USER_PASSWORD=
USER_SSHKEY=
SSH_PORT=
SSH_ALLOW_USERS=
TAILSCALE_AUTHKEY=
WIREGUARD_PRIKEY=
WIREGUARD_PUBKEY=
WIREGUARD_PORT=51000
WIREGUARD_PEER_PUBKEY=

apt update
apt-get install curl net-tools vim nano less apt-show-versions -y

curl -o prep_system.sh $URL_PREFIX/raw/main/scripts/prep_system.sh
chmod +x ./prep_system.sh
./prep_system.sh $LINODE_LISHUSERNAME

curl -o configure_user.sh $URL_PREFIX/raw/main/scripts/configure_user.sh
chmod +x ./configure_user.sh
./configure_user.sh $USER_NAME $USER_PASSWORD $SSH_PORT $USER_SSHKEY $SSH_ALLOW_USERS

curl -o install_tailscale.sh $URL_PREFIX/raw/main/scripts/install_tailscale.sh
chmod +x ./install_tailscale.sh
./install_tailscale.sh $TAILSCALE_AUTHKEY $LINODE_LISHUSERNAME

curl -o install_wireguard.sh $URL_PREFIX/raw/main/scripts/install_wireguard.sh
chmod +x ./install_wireguard.sh
./install_wireguard.sh wg0 $WIREGUARD_PRIKEY $WIREGUARD_PUBKEY $WIREGUARD_PEER_PUBKEY $WIREGUARD_PORT "10.10.0"
./install_wireguard.sh wg1 $WIREGUARD_PRIKEY $WIREGUARD_PUBKEY $WIREGUARD_PEER_PUBKEY $(($WIREGUARD_PORT+1000)) "10.10.1"
./install_wireguard.sh wg2 $WIREGUARD_PRIKEY $WIREGUARD_PUBKEY $WIREGUARD_PEER_PUBKEY $(($WIREGUARD_PORT+2000)) "10.10.2"
