#! /usr/bin/env bash
#apt install -y lvm2 #already available
pvcreate /dev/sdc
vgcreate cinder-volumes /dev/sdc
cp /vagrant/conf/lvm.conf /etc/lvm/lvm.conf
apt install y cinder-volume
cp /vagrant/conf/cinder.conf /etc/cinder/cinder.conf
service tgt restart
service cinder-volume restart