#!/bin/bash
USER_NAME=$1
USER_PASSWORD=$2
SSH_PORT=$3
USER_SSHKEY=$4
SSH_ALLOW_USERS=$5

# configure_ssh
#setup ssh
#add ssh key
sudo -u $USER_NAME mkdir /home/$USER_NAME/.ssh
sudo -u $USER_NAME echo "${USER_SSHKEY}" >> /home/$USER_NAME/.ssh/authorized_keys
mkdir -p /root/.ssh/
echo "${USER_SSHKEY}" >> /root/.ssh/authorized_keys
chmod 0600 /home/$USER_NAME/.ssh/authorized_keys /root/.ssh/authorized_keys
chown $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh/authorized_keys
sed -i "s/Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config #set ssh port
#enable internal sftp for chrooting
sed -i 's@Subsystem sftp /usr/lib/openssh/sftp-server@Subsystem sftp internal-sftp@' /etc/ssh/sshd_config
if [[ "$SSH_ALLOW_USERS" != *root* ]]
then
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
else
sed -i 's/PermitRootLogin yes/PermitRootLogin without-password/' /etc/ssh/sshd_config
fi
if [ ! -z "$USER_SSHKEY" ]
then
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config #disable ssh password auth if $USER_SSHKEY is not empty
fi
sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config #disable xforwarding
echo "AllowUsers $USER_NAME $SSH_ALLOW_USERS" >> /etc/ssh/sshd_config #only allow access from $USER
/etc/init.d/ssh restart

# configure_user
#configure ssh/sudo 
useradd -m -s /bin/bash $USER_NAME #add user account 
echo "$USER_NAME:$USER_PASSWORD" | chpasswd #setpassword
#add user to sudoers
echo "$USER_NAME ALL=(ALL) ALL" >> /etc/sudoers
usermod -a -G adm $USER_NAME
#lock out root
passwd -l root
