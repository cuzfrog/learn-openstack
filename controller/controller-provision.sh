#!/usr/bin/env bash

# Install mariadb and create keystone database.
apt install mariadb-server python-pymysql
cp /vagrant/mariadb.conf /etc/mysql/mariadb.conf.d/99-openstack.cnf
service mysql restart
mysql -u root -e 'CREATE DATABASE keystone;'
mysql -u root -e $'GRANT ALL PRIVILEGES ON keystone.* TO `keystone`@`%` IDENTIFIED BY \'boss1\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON keystone.* TO `keystone`@`localhost` IDENTIFIED BY \'boss1\';'

# Install RabbitMQ and memcached
apt install rabbitmq-server
rabbitmqctl add_user openstack boss1
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
apt install memcached python-memcache
service memcached restart

# Install keystone and bootstrap
apt install keystone
cp /vagrant/keystone.conf /etc/keystone/keystone.conf
su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
p0='--bootstrap-password boss1'
p1='--bootstrap-admin-url http://controller:35357/v3/'
p2='--bootstrap-internal-url http://controller:35357/v3/'
p3='--bootstrap-public-url http://controller:5000/v3/'
p4='--bootstrap-region-id RegionOne'
keystone-manage bootstrap $p0 $p1 $p2 $p3 $p4
