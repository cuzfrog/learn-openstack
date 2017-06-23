#!/usr/bin/env bash
username=ubuntu
echo "${username} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${username}
sudo su - ${username}
echo 'Defaults env_keep="http_proxy,https_proxy,no_proxy"' > /etc/sudoers.d/env-keep

# Basic provision
echo "tmpfs /tmp tmpfs rw,nosuid,nodev,noatime" >> /etc/fstab
cat /vagrant/env/hosts > /etc/hosts
cat /vagrant/env/envs >> /etc/environment
cat /vagrant/env/apt-proxy > /etc/apt/apt.conf
cp /vagrant/env/artful-au-sources.list /etc/apt/sources.list

# Initialize apt
#apt -o Acquire::https::No-Cache=True -o Acquire::http::No-Cache=True update
apt update
apt install -y software-properties-common python-software-properties
add-apt-repository -y cloud-archive:newton
apt update

# Install OpenStack-cli and chrony
apt install -y python-openstackclient
apt install -y chrony
echo "allow 172.22.6.0/24" >> /etc/chrony/chrony.conf
service chrony restart
