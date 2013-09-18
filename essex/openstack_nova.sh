#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "You need to be 'root' dude." 1>&2
   exit 1
fi

host_ip=$(/sbin/ifconfig eth0| sed -n 's/.*inet *addr:\([0-9\.]*\).*/\1/p')
echo "#############################################################################################################"
echo "The IP address for eth0 is probably $host_ip".
echo "#############################################################################################################"
read -p "Enter the ServerControlIP interface IP: " host_ip_entry
read -p "Enter the admin password : " SERVICE_PASSWORD


# get nova
apt-get install -y nova-api nova-cert nova-common nova-doc nova-network nova-objectstore nova-scheduler nova-vncproxy nova-volume python-nova python-novaclient

. ./stackrc

password=$SERVICE_PASSWORD

# hack up the nova paste file
sed -e "
s,%SERVICE_TENANT_NAME%,admin,g;
s,%SERVICE_USER%,admin,g;
s,%SERVICE_PASSWORD%,$password,g;
" -i /etc/nova/api-paste.ini
 
# write out a new nova file
echo "
# Logs/State
--verbose=False

# Authentication
--auth_strategy=keystone

# Ccheduler
--scheduler_driver=nova.scheduler.simple.SimpleScheduler

# Volumes
--volume_group=nova-volumes
--iscsi_helper=tgtadm

# Datebase
--sql_connection=mysql://nova:$password@127.0.0.1/nova

# Nova
--logdir=/var/log/nova
--state_path=/var/lib/nova
--lock_path=/var/lock/nova
--allow_admin_api=true
--use_deprecated_auth=false
--connection_type=libvirt
--root_helper=sudo nova-rootwrap

# API
--s3_host=$host_ip_entry
--ec2_host=$host_ip_entry
--cc_host=$host_ip_entry
--nova_url=http://$host_ip_entry:8774/v1.1/
--ec2_url=http://$host_ip_entry:8773/services/Cloud
--keystone_ec2_url=http://$host_ip_entry:5000/v2.0/ec2tokens
--api_paste_config=/etc/nova/api-paste.ini


# Rabbit
--rabbit_host=$host_ip_entry

# Glance
--glance_api_servers=$host_ip_entry:9292
--image_service=nova.image.glance.GlanceImageService


# Compute
--libvirt_type=kvm
--libvirt_use_virtio_for_bridges=true
--start_guests_on_host_boot=true
--resume_guests_state_on_host_boot=true

# Console
--novnc_enabled=true
--novncproxy_base_url= http://$host_ip_entry:6080/vnc_auto.html
--vncserver_proxyclient_address=$host_ip_entry
--vncserver_listen=$host_ip_entry

# Network
--network_manager=nova.network.manager.FlatDHCPManager
--dhcpbridge_flagfile=/etc/nova/nova.conf
--dhcpbridge=/usr/bin/nova-dhcpbridge
--public_interface=eth0
--flat_interface=eth0
--flat_network_bridge=br100
--fixed_range=10.0.0.0/8
--flat_injected=False
--force_dhcp_release=True
--multi_host=True
" > /etc/nova/nova.conf

# sync db
nova-manage db sync

# restart nova
./openstack_restart_nova.sh


# do we need this?
chown -R nova:nova /etc/nova/

echo "#######################################################################################"
echo "'nova list' and a 'nova image-list' to test.  Do './openstack_horizon.sh' next."
echo "#######################################################################################"

