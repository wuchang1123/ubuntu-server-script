#!/bin/bash

WIREGUARD_IFNAME=$1
WIREGUARD_PRIKEY=$2
WIREGUARD_PUBKEY=$3
WIREGUARD_PEER_PUBKEY=$4
WIREGUARD_PORT=$5
WIREGUARD_NET_PREFIX=$6

apt install wireguard -y
mkdir -p /etc/wireguard

if [ ! -z "$WIREGUARD_PRIKEY" ]
  then
  echo "${WIREGUARD_PRIKEY}" > /etc/wireguard/private.key
fi
if [ ! -z "$WIREGUARD_PUBKEY" ]
  then
  echo "${WIREGUARD_PUBKEY}" > /etc/wireguard/public.key
fi
if [ ! -f "/etc/wireguard/private.key" ];then
wg genkey | sudo tee /etc/wireguard/private.key
cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key
fi
WIREGUARD_PRIKEY=`cat /etc/wireguard/private.key`
WIREGUARD_PUBKEY=`cat /etc/wireguard/public.key`
if [ ! -f "/etc/wireguard/post_up.sh" ];then
cat > /etc/wireguard/post_up.sh <<EOF
#!/bin/sh
iptables -t nat -I POSTROUTING -s \$3 -o \$1 -j MASQUERADE
iptables -I INPUT -i \$2 -j ACCEPT
iptables -I FORWARD -i \$1 -o \$2 -j ACCEPT
iptables -I FORWARD -i \$2 -o \$1 -j ACCEPT
iptables -I INPUT -i \$1 -p udp --dport \$4 -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport \$5 -j REDIRECT --to-ports \$4
EOF
cat > /etc/wireguard/post_down.sh <<EOF
#!/bin/sh
iptables -t nat -D POSTROUTING -s \$3 -o \$1 -j MASQUERADE
iptables -D INPUT -i \$2 -j ACCEPT
iptables -D FORWARD -i \$1 -o \$2 -j ACCEPT
iptables -D FORWARD -i \$2 -o \$1 -j ACCEPT
iptables -D INPUT -i \$1 -p udp --dport \$4 -j ACCEPT
iptables -D nat -A PREROUTING -p udp --dport \$5-j REDIRECT --to-ports \$4
EOF
fi
cat > /etc/wireguard/$WIREGUARD_IFNAME.conf <<EOF
[Interface]
Address = $WIREGUARD_NET_PREFIX.1/24
PostUp = /etc/wireguard/post_up.sh eth0 $1 $WIREGUARD_NET_PREFIX.0/24 $WIREGUARD_PORT "$(($WIREGUARD_PORT+1)):$(($WIREGUARD_PORT+999))"
PostDown = /etc/wireguard/post_down.sh eth0 $1 $WIREGUARD_NET_PREFIX.0/24 $WIREGUARD_PORT "$(($WIREGUARD_PORT+1)):$(($WIREGUARD_PORT+999))"
ListenPort = $WIREGUARD_PORT
PrivateKey = $WIREGUARD_PRIKEY
MTU=1280
[Peer]
PublicKey = $WIREGUARD_PEER_PUBKEY
AllowedIPs = $WIREGUARD_NET_PREFIX.2/32
EOF
chmod +x /etc/wireguard/post_up.sh
chmod +x /etc/wireguard/post_down.sh
echo $WIREGUARD_IFNAME
echo $WIREGUARD_PORT
ufw allow $WIREGUARD_PORT/udp
systemctl enable wg-quick@$WIREGUARD_IFNAME
systemctl start wg-quick@$WIREGUARD_IFNAME
