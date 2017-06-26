#!/usr/bin/env bash
# Setup user
username=vagrant
useradd $username
echo "$username:$username" | chpasswd
echo "${username} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${username}
mkdir -p /home/$username/.ssh
cp /vagrant/vagrant.pub /home/$username/.ssh/authorized_keys
chmod 700 /home/$username/.ssh
chmod 600 /home/$username/.ssh/authorized_keys
chown -R ${username}:${username} /home/$username/.ssh
