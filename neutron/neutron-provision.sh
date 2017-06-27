#!/usr/bin/env bash
bash
apt update

# Setup network and install neutron
cp /vagrant/conf/sysctl.conf /etc/sysctl.conf
sysctl –p
apt install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent > /dev/null

