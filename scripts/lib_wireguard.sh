function install_wireguard
{
apt-get install wireguard -y
if [ "$WIREGUARD_PRIKEY" != "" ]
  then
  echo "${WIREGUARD_PRIKEY}" > /etc/wireguard/private.key
fi
if [ "$WIREGUARD_PUBKEY" != "" ]
  then
  echo "${WIREGUARD_PUBKEY}" > /etc/wireguard/public.key
fi
if [ ! -f "/etc/wireguard/private.key" ];then
wg genkey | sudo tee /etc/wireguard/private.key
cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key
fi
private_key=`cat /etc/wireguard/private.key`
public_key=`cat /etc/wireguard/public.key`
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
cat > /etc/wireguard/$1.conf <<EOF
[Interface]
Address = $2.1/24
PostUp = /etc/wireguard/post_up.sh eth0 $1 $2.0/24 $3 $5
PostDown = /etc/wireguard/post_down.sh eth0 $1 $2.0/24 $3 $5
ListenPort = $3
PrivateKey = $private_key
MTU=1280
[Peer]
PublicKey = $4
AllowedIPs = $2.2/32
EOF
chmod +x /etc/wireguard/post_up.sh
chmod +x /etc/wireguard/post_down.sh
# ufw allow $3/udp
systemctl enable wg-quick@$1
systemctl start wg-quick@$1
}