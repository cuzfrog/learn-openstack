#!/usr/bin/env bash


#cat /vagrant/hosts > /etc/hosts
cat /vagrant/envs >> /etc/environment
#cat /vagrant/apt-proxy > /etc/apt/apt.conf
#cp /vagrant/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo

#sudo systemctl disable NetworkManager
#sudo systemctl stop NetworkManager
#sudo systemctl enable network
#sudo systemctl start network

sudo yum install -y centos-release-openstack-ocata
sudo yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm
sudo yum update -y
sudo yum install -y openstack-packstack

cp /vagrant/CentOS-OpenStack-ocata.repo /etc/yum.repos.d/CentOS-OpenStack-ocata.repo
