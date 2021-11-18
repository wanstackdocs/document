1. 用户登录，登录系统可操作页面

2. 部署操作，一套openstack环境为一条记录（删除为假删除，隐藏），详情页可配置openstack，安装。先安装controller节点，计算节点使用ansible批量安装，安装节点错误后回退(使用cobbler重新安装操作系统，如果不支持可以手动安装)

3. 日志搜集，搜集安装日志(提供安装进度条)，搜集openstack 运行日志(字段解析) LOKI

4. webssh功能, 每个node节点可以webssh, 

5. 安装脚本，安装脚本分模块化安装，目前分为2种角色，controller和compute角色，或者2种角色都选择，或者只选择其中一种，但是必须得选择一种。选择完成后是否需要更改？？？





## 1. 部署方式
1）用户安装操作系统
2）用户安装cpmg系统
3）登录cpmg系统，创建openstack环境，使用cobbler安装操作系统，节点发现，添加openstack节点，选择node角色， 修改配置文件，安装openstack集群环境

## 2. 功能列表
### 1. 用户管理(system)
1）管理员可以管理用户、包括新建、修改、删除等
2）普通用户仅可以查看、修改自己账号，可以安装配置openstack环境

### 2. 安装配置(manage)
1. node管理
1）使用cobbler 安装操作系统，仅仅配置pex网络网卡地址, pex网络和集群网络网卡复用

2）节点发现 -- 发现安装好的操作系统，关联角色(控制节点、计算节点、ALL_IN_ONE) # 定时任务？
信息：IP地址、ssh port，root账号，root密码/公钥

3）配置管理 -- 网络配置、账号配置

网络配置: 主要配置，在配置上联 交换机时，公开网络、集群网络、BR-MIRROR 网络 务必配置成同一个VLAN ，BR-VLAN网络配置成TRUNK模式

网卡tag：网卡和网卡tag进行关联，然后配置网卡tag
1. 公开，br-ex, web访问dashboard
公共网络允许从外部网络（例如Internet）到虚拟机的向内网络连接，以及从虚拟机到外部网络的向外网络连接。
CIDR(子网掩码)10.100.7.0/24，IP RANGE(10.100.7.1,10.100.7.99), 网关(10.100.7.254)

下面的地址段范围 不能和上面的 IP RANGE 重合
EX_GATEWAY="10.100.7.254"
LOCAL_CIDR="10.100.7.0/24"
IP_POOL_START="10.100.7.100"
IP_POOL_END="10.100.7.200"

2. 集群，主机解析，集群内部API通信，比如nova-api 访问 neutron-api接口等
CIDR(子网掩码, 192.168.7.0/24)，IP RANGE(192.168.7.1,192.168.7.200)   pex网络和集群网络网卡复用。
首先使用pex网络进行DHCP分配，分配的地址记录在数据库种，再安装openstack环境时，写静态IP地址。

3. BR-MIRROR， 不配置IP地址

4. BR-VLAN 此网卡上联交换机必须为TRUNK，不配置IP地址

连通性检查，



账号配置：
rabbitmq用户与密码
RABBITMQ_USER="openstack"
RABBITMQ_PASSWD=Hp6GWR1r6CVFOM5

Mariadb服务的root密码
MARIADB_ROOT_PASSWD=iAdBLsIQx4qSpVN

MARIADB_CRDBUSER_PASS=iAdBLsIQx4qSpVN

admin用户密码
ADMIN_PASSWD=7gqiMnynHErdrjc

密码复杂性检查：



openstack模块化管理: 是否以插件形式提供选择模块安装


### 3. 日志配置:
LOKI C/S ,配置文件暂时未提供，搜集openstack安装信息日志，搜集openstack运行日志。

### 4. 安装部署: 
ansible获取node节点信息，分配完成角色，先安装控制节点，然后安装计算节点（批量，是否规定上限）。
关于回退: 安装过程中如果安装失败，回退是否可以使用cobbler重新安装操作系统，需要人工干预从网络启动。


### 5. 节点管理: webssh管理





python manage.py makemigrations
python manage.py migrate
(cpos) [root@localhost cpos]# python manage.py createsuperuser
用户名: admin
电子邮件地址: admin@example.com
Password:  admin
Password (again): 
密码跟 用户名 太相似了。
密码长度太短。密码必须包含至少 8 个字符。
这个密码太常见了。
Bypass password validation and create user anyway? [y/N]: y
Superuser created successfully.



