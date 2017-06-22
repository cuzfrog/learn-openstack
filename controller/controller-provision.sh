#!/usr/bin/env bash

# Install mariadb and create keystone database.
apt install -y mariadb-server python-pymysql
cp /vagrant/conf/mariadb.conf /etc/mysql/mariadb.conf.d/99-openstack.cnf
service mysql restart
mysql -u root -e 'CREATE DATABASE keystone;'
mysql -u root -e $'GRANT ALL PRIVILEGES ON keystone.* TO `keystone`@`%` IDENTIFIED BY \'keystone_password\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON keystone.* TO `keystone`@`localhost` IDENTIFIED BY \'keystone_password\';'
mysql -u root -e 'CREATE DATABASE glance;'
mysql -u root -e $'GRANT ALL PRIVILEGES ON glance.* TO `glance`@`localhost` IDENTIFIED BY \'glance_password\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON glance.* TO `glance`@`%` IDENTIFIED BY \'glance_password\';'
mysql -u root -e 'CREATE DATABASE nova_api;'
mysql -u root -e 'CREATE DATABASE nova;'
mysql -u root -e $'GRANT ALL PRIVILEGES ON nova_api.* TO `nova`@`localhost` IDENTIFIED BY \'nova_password\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON nova_api.* TO `nova`@`%` IDENTIFIED BY \'nova_password\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON nova.* TO `nova`@`localhost` IDENTIFIED BY \'nova_password\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON nova.* TO `nova`@`%` IDENTIFIED BY \'nova_password\';'
mysql -u root -e 'CREATE DATABASE neutron;'
mysql -u root -e $'GRANT ALL PRIVILEGES ON neutron.* TO `neutron`@`localhost` IDENTIFIED BY \'neutron_password\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON neutron.* TO `neutron`@`%` IDENTIFIED BY \'neutron_password\';'

# Install RabbitMQ and memcached
apt install -y rabbitmq-server
rabbitmqctl add_user openstack rabbitmq_password
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
apt install -y memcached python-memcache
cp /vagrant/conf/memcached.conf /etc/memcached.conf
service memcached restart

# Install keystone and bootstrap
apt install -y keystone
cp /vagrant/conf/keystone.conf /etc/keystone/keystone.conf
su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
p0='--bootstrap-password boss1'
p1='--bootstrap-admin-url http://controller:35357/v3/'
p2='--bootstrap-internal-url http://controller:35357/v3/'
p3='--bootstrap-public-url http://controller:5000/v3/'
p4='--bootstrap-region-id RegionOne'
keystone-manage bootstrap $p0 $p1 $p2 $p3 $p4

# Create admin service and demo service/role/user
. /vagrant/conf/admin-openrc
openstack project create --domain default --description "Service Project" service
#openstack project create --domain default --description "Demo Project" demo

# Setup glance service
openstack user create --domain default --password glance_password glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

# Install glance
apt install -y glance
cp /vagrant/conf/glance-api.conf /etc/glance/glance-api.conf
cp /vagrant/conf/glance-registry.conf /etc/glance/glance-registry.conf
su -s /bin/sh -c "glance-manage db_sync" glance
service glance-registry restart
service glance-api restart
wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
openstack image create "cirros" --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --public

# Setup and Install compute (controller)
openstack user create --domain default --password nova_password nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1/%\(tenant_id\)s
apt install -y nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler
cp /vagrant/conf/nova.conf /etc/nova/nova.conf
nova-manage api_db sync nova
nova-manage db sync nova
service nova-api restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

# Setup neutron (controller)
openstack user create --domain default --password neutron_password neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
