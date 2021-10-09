neutron net-create --provider:network_type=flat --provider:physical_network=provider  --shared oj_ext

neutron subnet-create --allocation-pool start=10.100.8.100,end=10.100.8.200 --enable-dhcp --gateway 10.100.8.254 --ip-version 4 --name subnet oj_ext 10.100.8.0/24


nova boot --image cirros --flavor small --nic net-id=a40f2745-26f3-4953-90b1-32c4282fab1c  --poll test >/dev/null


openstack  flavor create --ram 1024 --disk 10 --vcpus 2 small


GRANT ALL PRIVILEGES ON *.* TO 'root'@'*' IDENTIFIED BY '123456';

openstack image create "Cisco-3"   --file c8000v-universalk9_8G_serial.17.04.01a.qcow2  --disk-format qcow2 --container-format bare  --public



rabbitmqctl add_user openstack openstack

rabbitmqctl set_permissions -p / openstack ".*" ".*" ".*"



drop database nova;
drop database nova_api;
drop database nova_cell0;
create database nova;
create database nova_api;
create database nova_cell0

su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova

systemctl restart apache2
systemctl restart openstack-nova-*


nova-status upgrade check
nova-manage cell_v2 discover_hosts


source admin.openrc

nova service-list



pip install --no-index --find-links=/data/openstack/pip -r requirements.txt



qemu-img convert -U -O qcow2 /var/lib/nova/instances/$vm_uuid/disk Cisco_Router.qcow2 -p


qemu-img convert -U -O qcow2 disk Cisco_Router.qcow2 -p