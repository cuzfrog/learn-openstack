#!/usr/bin/env bash
bash
apt update

# Setup time sync
cp /vagrant/conf/chrony.conf /etc/chrony/chrony.conf
service chrony restart


apt install -y nova-compute
cp /vagrant/conf/nova /etc/nova/nova.conf
cp /vagrant/conf/nova-compute.conf /etc/nova/nova-compute.conf
#service nova-compute restart

cp /vagrant/conf/sysctl.conf /etc/sysctl.conf
apt install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent
cp /vagrant/conf/neutron.conf /etc/neutron/neutron.conf
cp /vagrant/conf/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
service nova-compute restart
service neutron-openvswitch-agent restart
service openvswitch-switch restart
