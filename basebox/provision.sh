#!/usr/bin/env bash

# Basic provision
echo 'Defaults env_keep="http_proxy,https_proxy,no_proxy"' > /etc/sudoers.d/env-keep
echo "tmpfs /tmp tmpfs rw,nosuid,nodev,noatime" >> /etc/fstab
cat /vagrant/env/hosts > /etc/hosts
cat /vagrant/env/envs >> /etc/environment
cat /vagrant/env/apt-proxy > /etc/apt/apt.conf
cp /vagrant/env/artful-au-sources.list /etc/apt/sources.list

# Initialize apt
apt -o Acquire::https::No-Cache=True -o Acquire::http::No-Cache=True update
#apt update
apt install -y software-properties-common python-software-properties
add-apt-repository -y cloud-archive:newton
apt -o Acquire::https::No-Cache=True -o Acquire::http::No-Cache=True update

# Install basic tools
apt install -y nmap htop linux-headers-$(uname -r) build-essential dkms

# Install VirtualBoxGuestAddition
mount /dev/cdrom /media/cdrom
sh /media/cdrom/VBoxLinuxAdditions.run

# Install OpenStack-cli and chrony
apt install -y python-openstackclient
apt install -y chrony
#echo "allow 172.22.6.0/24" >> /etc/chrony/chrony.conf
#cp /vagrant/conf/chrony.conf /etc/chrony/chrony.conf
#service chrony restart
