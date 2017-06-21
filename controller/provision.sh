#!/usr/bin/env bash
username=ubuntu
echo "${username} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${username}
sudo su - ${username}

# Basic provision
cat /vagrant/hosts > /etc/hosts
cat /vagrant/envs >> /etc/environment
cat /vagrant/apt-proxy > /etc/apt/apt.conf
cp /vagrant/artful-au-sources.list /etc/apt/sources.list

# Initialize apt
apt update
apt install -y software-properties-common python-software-properties
add-apt-repository -y cloud-archive:newton
apt update

# Install OpenStack-cli and chrony
apt install -y python-openstackclient
apt install -y chrony
echo "allow 172.22.6.0/24" >> /etc/chrony/chrony.conf
service chrony restart
