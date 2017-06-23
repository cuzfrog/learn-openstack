#!/usr/bin/env bash
username=ubuntu
echo "${username} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${username}
sudo su - ${username}

# Basic provision
echo "tmpfs /tmp tmpfs rw,nosuid,nodev,noatime" >> /etc/fstab
cat /vagrant/env/hosts > /etc/hosts
cat /vagrant/env/envs >> /etc/environment
cat /vagrant/env/apt-proxy > /etc/apt/apt.conf
cp /vagrant/env/artful-au-sources.list /etc/apt/sources.list

# Initialize apt
apt update
apt install -y software-properties-common python-software-properties
add-apt-repository -y cloud-archive:newton
apt update

# Install OpenStack-cli and chrony
apt install -y python-openstackclient
apt install -y chrony
cp /vagrant/conf/chrony.conf /etc/chrony/chrony.conf
service chrony restart
