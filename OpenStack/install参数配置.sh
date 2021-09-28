
controller:
## 当前节点类型,controller,node,network,cinder
CURRENT_NODE_TYPE="controller"

## 集群是否为all-in-one,选填True/False
ALL_IN_ONE=True

## 控制节点主机名
CONTROLLER_HOSTNAME="controller"

## 本机主机名
LOCAL_HOSTNAME="controller"

## WEB访问地址
WEB_IP="10.100.7.1"

## 本机与管理段通信的IP地址
LOCAL_IP="172.30.3.45"

## 用于虚拟机与外部网络通信的网卡名称，与web口同用
BR_EX_INTERFACE_NAME="eno2"

EX_GATEWAY="10.100.7.254"
LOCAL_CIDR="10.100.7.0/24"
IP_POOL_START="10.100.7.100"
IP_POOL_END="10.100.7.200"

##管理段通信网卡名称
BR_MANAGER_INTERFACE_NAME="eno4"

## 用于流量镜像到实体设备的网卡名称，独立使用不能混用
BR_MIRROR_INTERFACE_NAME="eno1"

## 数据网络通信接口的网卡名称与IP地址,独立使用不能混用
BR_VLAN_INTERFACE_NAME="eno3"

## chrony允许通过的网段,如果有多个网段中间用空格分割,默认允许所有,例如:ALLOW_CHRONY_NETWORKS="10.0.0.0/24 20.0.0.0/24"
#ALLOW_CHRONY_NETWORKS="*"
ALLOW_CHRONY_NETWORKS="172.30.3.0/24"

## 控制节点管理段IP地址,即控制节点与各个计算节点、存储节点、网络节点相互通信的地址
CONTROLLER_MANAGEMENT_IP="172.30.3.45"





eno2: 10.100.7.1
eno4: 172.30.3.45



nohup bash install.sh >> /opt/rsync/sync.log 2>&1 &




compute:

## 当前节点类型,controller,node,network,cinder
CURRENT_NODE_TYPE="node"

## 集群是否为all-in-one,选填True/False
ALL_IN_ONE=False

## 控制节点主机名
CONTROLLER_HOSTNAME="controller"

## 本机主机名
LOCAL_HOSTNAME="compute46"

## WEB访问地址
WEB_IP="10.100.7.1"

## 本机与管理段通信的IP地址
LOCAL_IP="172.30.3.46"

## 用于虚拟机与外部网络通信的网卡名称，与web口同用
BR_EX_INTERFACE_NAME="enp3s0f0"

EX_GATEWAY="10.100.7.254"
LOCAL_CIDR="10.100.7.0/24"
IP_POOL_START="10.100.7.100"
IP_POOL_END="10.100.7.200"

##管理段通信网卡名称
BR_MANAGER_INTERFACE_NAME="enp3s0f1"

## 用于流量镜像到实体设备的网卡名称，独立使用不能混用
BR_MIRROR_INTERFACE_NAME="ens1f0"

## 数据网络通信接口的网卡名称与IP地址,独立使用不能混用
BR_VLAN_INTERFACE_NAME="ens1f1"

## chrony允许通过的网段,如果有多个网段中间用空格分割,默认允许所有,例如:ALLOW_CHRONY_NETWORKS="10.0.0.0/24 20.0.0.0/24"
#ALLOW_CHRONY_NETWORKS="*"
ALLOW_CHRONY_NETWORKS="172.30.3.0/24"

## 控制节点管理段IP地址,即控制节点与各个计算节点、存储节点、网络节点相互通信的地址
CONTROLLER_MANAGEMENT_IP="172.30.3.45"




enp3s0f0:10.100.7.5
enp3s0f1:172.30.3.46



