#!/usr/bin/env bash

# Setup time sync
cp /vagrant/conf/chrony.conf /etc/chrony/chrony.conf
service chrony restart


apt install -y nova-compute
cp /vagrant/conf/nova /etc/nova/nova.conf
cp /vagrant/conf/nova-compute.conf /etc/nova/nova-compute.conf
service nova-compute restart
