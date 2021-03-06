#!/usr/bin/env bash
bash
apt update
# Setup time sync
echo "allow 172.22.6.0/24" >> /etc/chrony/chrony.conf
service chrony restart

# Install mariadb and create keystone database.
apt install -y mariadb-server python-pymysql > /dev/null
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
mysql -u root -e 'CREATE DATABASE nova_cell0;'
mysql -u root -e $'GRANT ALL PRIVILEGES ON nova_api.* TO `nova`@`localhost` IDENTIFIED BY \'nova_password\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON nova_api.* TO `nova`@`%` IDENTIFIED BY \'nova_password\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON nova.* TO `nova`@`localhost` IDENTIFIED BY \'nova_password\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON nova.* TO `nova`@`%` IDENTIFIED BY \'nova_password\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON nova_cell0.* TO `nova`@`localhost` IDENTIFIED BY \'nova_password\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON nova_cell0.* TO `nova`@`%` IDENTIFIED BY \'nova_password\';'
mysql -u root -e 'CREATE DATABASE neutron;'
mysql -u root -e $'GRANT ALL PRIVILEGES ON neutron.* TO `neutron`@`localhost` IDENTIFIED BY \'neutron_password\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON neutron.* TO `neutron`@`%` IDENTIFIED BY \'neutron_password\';'
mysql -u root -e 'CREATE DATABASE cinder;'
mysql -u root -e $'GRANT ALL PRIVILEGES ON cinder.* TO `cinder`@`localhost` IDENTIFIED BY \'cinder_password\';'
mysql -u root -e $'GRANT ALL PRIVILEGES ON cinder.* TO `cinder`@`%` IDENTIFIED BY \'cinder_password\';'
echo "db setup!"

# Install RabbitMQ and memcached
apt install -y rabbitmq-server > /dev/null
rabbitmqctl add_user openstack rabbitmq_password
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
apt install -y memcached python-memcache > /dev/null
cp /vagrant/conf/memcached.conf /etc/memcached.conf
service memcached restart
echo "mq setup!"

# Install keystone and bootstrap
apt install -y keystone > /dev/null
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
echo "keystone setup!"

# Create admin service and demo service/role/user
. /vagrant/admin-openrc
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
apt install -y glance > /dev/null
cp /vagrant/conf/glance-api.conf /etc/glance/glance-api.conf
cp /vagrant/conf/glance-registry.conf /etc/glance/glance-registry.conf
su -s /bin/sh -c "glance-manage db_sync" glance
service glance-registry restart
service glance-api restart
wget --quiet http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
openstack image create "cirros" --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --public
echo "glance and image setup!"

# Setup and Install compute (controller)
openstack user create --domain default --password nova_password nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1/%\(tenant_id\)s
apt install -y nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler > /dev/null
cp /vagrant/conf/nova.conf /etc/nova/nova.conf
su -s /bin/sh -c "nova-manage cell_v2 simple_cell_setup"
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova
service nova-api restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
echo "nova setup!"

# Setup neutron (controller)
openstack user create --domain default --password neutron_password neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696
apt install -y neutron-server neutron-plugin-ml2 > /dev/null
 #neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent
cp /vagrant/conf/neutron.conf /etc/neutron/neutron.conf
cp /vagrant/conf/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service neutron-server restart
echo "neutron setup!"

# Setup cinder (controller)
openstack user create --domain default --password cinder_password cinder
openstack role add --project service --user cinder admin
openstack service create --name cinder --description "OpenStack Block Storage" volume
openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack endpoint create --region RegionOne volume public http://controller:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volume internal http://controller:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volume admin http://controller:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 public http://controller:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://controller:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://controller:8776/v2/%\(tenant_id\)s
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3
openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://controller:8776/v3/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://controller:8776/v3/%\(tenant_id\)s
apt install -y cinder-api cinder-scheduler > /dev/null
cp /vagrant/conf/cinder.conf /etc/cinder/cinder.conf
su -s /bin/sh -c "cinder-manage db sync" cinder
service nova-api restart
service cinder-scheduler restart
#service cinder-api restart #service not found
echo "cinder setup!"

# Install horizon
apt install -y python-django openstack-dashboard
cp /vagrant/conf/local_settings.py /etc/openstack-dashboard/local_settings.py
service apache2 reload

# Add more user and project
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password password1 user1
openstack role add --project demo --user user1 _member_
