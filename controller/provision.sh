#!/usr/bin/env bash
username=ubuntu
#sudo useradd -s /bin/bash -d /opt/stack -m stack
echo "${username} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${username}
sudo su - ${username}


cat /vagrant/hosts > /etc/hosts
cat /vagrant/envs >> /etc/environment
cat /vagrant/apt-proxy > /etc/apt/apt.conf
cp /vagrant/apt-sources.list /etc/apt/sources.list


#apt update
#apt install -y software-properties-common python-software-properties
#add-apt-repository -y cloud-archive:newton
#apt update
#apt install -y chrony
#echo "allow 192.168.0.0/24" >> /etc/chrony/chrony.conf
#service chrony restart
#apt install -y python-openstackclient
