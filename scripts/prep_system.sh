#!/bin/bash
PRIMARY_IP=echo $(ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1)

#update system
apt-get -y update

# apt-get install debconf-utils -y
# debconf-set-selections <<< "postfix postfix/mailname $ROOT_EMAIL"
# debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

#apt-get -y upgrade

#setup hostname
export HOSTNAME=$1
HOST=$(echo $HOSTNAME | sed 's/\(\[a-z0-9\]\)*\..*/\1/')
echo "$HOST" >  /etc/hostname
echo "$PRIMARY_IP $HOSTNAME $HOST" >> /etc/hosts

#start hostname
hostnamectl set-hostname $HOSTNAME
echo "/usr/sbin/nologin" >> /etc/shells

#set timezone to UTC
ln -s -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# rc-local
cat > /etc/rc.local <<EOF
#!/bin/sh
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
EOF
cat >> /lib/systemd/system/rc-local.service <<EOF
[Install]
WantedBy=multi-user.target
Alias=rc-local.service
EOF
chmod +x /etc/rc.local
ln -s /lib/systemd/system/rc-local.service /etc/systemd/system/

# immediately
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/" /etc/sysctl.conf
sed -i "s/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/" /etc/sysctl.conf
sed -i "s/#net.ipv4.conf.all.accept_redirects = 0/net.ipv4.conf.all.accept_redirects = 0/" /etc/sysctl.conf
sed -i "s/#net.ipv4.conf.all.send_redirects = 0/net.ipv4.conf.all.send_redirects = 0/" /etc/sysctl.conf
sysctl -p
