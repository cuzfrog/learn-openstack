#! /usr/bin/env bash

# Setup time sync
cp /vagrant/conf/chrony.conf /etc/chrony/chrony.conf
service chrony restart


#apt install -y lvm2 #already available
pvcreate /dev/sdc
vgcreate cinder-volumes /dev/sdc
cp /vagrant/conf/lvm.conf /etc/lvm/lvm.conf
apt install y cinder-volume
cp /vagrant/conf/cinder.conf /etc/cinder/cinder.conf
service tgt restart
service cinder-volume restart
