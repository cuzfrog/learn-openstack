#!/usr/bin/env bash
bash
apt update

# Setup network and install neutron
cp /vagrant/conf/sysctl.conf /etc/sysctl.conf
#sysctl –p
apt install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent > /dev/null
cp /vagrant/conf/neutron.conf /etc/neutron/neutron.conf
cp /vagrant/conf/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
cp /vagrant/conf/l3_agent.ini /etc/neutron/l3_agent.ini
cp /vagrant/conf/metadata_agent.ini /etc/neutron/metadata_agent.ini

service openvswitch-switch restart
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex enp0s3

sudo service neutron-plugin-openvswitch-agent restart
sudo service neutron-l3-agent restart
sudo service neutron-dhcp-agent restart
sudo service neutron-metadata-agent restart
echo "neutron setup!"
