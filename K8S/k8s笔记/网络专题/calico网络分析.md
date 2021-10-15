[toc]

## 1. calico pod之前ping 分析(IPIP)

### 1.1 master上查看
```shell
[root@master 05]# k get pods -o wide
NAME                                             READY   STATUS      RESTARTS   AGE     IP                NODE     NOMINATED NODE   READINESS GATES
kubias-p7wv5                                     1/1     Running     0          74m     172.165.231.156   node02   <none>           <none>
kubias-q2h4p                                     1/1     Running     0          74m     172.173.55.45     node01   <none>           <none>

[root@master 05]# k exec -ti kubias-q2h4p /bin/bash
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
root@kubias-q2h4p:/# ip a 
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
4: eth0@if9: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1440 qdisc noqueue state UP group default 
    link/ether 7e:d0:87:56:77:75 brd ff:ff:ff:ff:ff:ff
    inet 172.173.55.45/32 scope global eth0
       valid_lft forever preferred_lft forever


# 现在使用node02上的pod称为pod2，ip地址是172.165.231.156 ping node01上的pod称为pod1，ip地址是 172.173.55.45
# 现在pod2 ping pod1
root@kubias-p7wv5:/# ping 172.173.55.45
PING 172.173.55.45 (172.173.55.45): 56 data bytes
64 bytes from 172.173.55.45: icmp_seq=0 ttl=62 time=0.498 ms
64 bytes from 172.173.55.45: icmp_seq=1 ttl=62 time=0.496 ms
64 bytes from 172.173.55.45: icmp_seq=2 ttl=62 time=0.455 ms
64 bytes from 172.173.55.45: icmp_seq=3 ttl=62 time=0.523 ms


# node02上pod的路由信息，ping 172.173.55.45 会匹配到第一条，第一条路由的意思是：去往任何网段的数据包都发往网169.254.1.1，然后从eth0网卡发送出去。
路由表中Flags标志的含义：

U up表示当前为启动状态
H host表示该路由为一个主机，多为达到数据包的路由
G Gateway 表示该路由是一个网关，如果没有说明目的地是直连的
D Dynamicaly 表示该路由是重定向报文修改
M 表示该路由已被重定向报文修改

root@kubias-p7wv5:/# ip route 
default via 169.254.1.1 dev eth0 
169.254.1.1 dev eth0  scope link 

root@kubias-p7wv5:/# cat /sys/class/net/eth0/iflink
25

root@kubias-p7wv5:/# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
4: eth0@if25: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1440 qdisc noqueue state UP group default 
    link/ether ce:d3:51:1a:8d:fe brd ff:ff:ff:ff:ff:ff
    inet 172.165.231.156/32 scope global eth0
       valid_lft forever preferred_lft forever  # veth对，连接到了node02上的25的网卡上，如下面




```


### 1.2 node02上查看

```shell
# node02上 ip a
25: cali0f418edccea@if4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1440 qdisc noqueue state UP group default 
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link 
       valid_lft forever preferred_lft forever


node02上的路由信息：
[root@node02 ~]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.101.1   0.0.0.0         UG    0      0        0 ens33
169.254.0.0     0.0.0.0         255.255.0.0     U     1002   0        0 ens33
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
172.165.231.128 0.0.0.0         255.255.255.192 U     0      0        0 *
172.165.231.156 0.0.0.0         255.255.255.255 UH    0      0        0 cali0f418edccea
172.165.231.159 0.0.0.0         255.255.255.255 UH    0      0        0 calicb87ff86d8f
172.165.231.162 0.0.0.0         255.255.255.255 UH    0      0        0 caliaeb68ccb938
172.171.205.128 192.168.101.100 255.255.255.192 UG    0      0        0 tunl0
172.173.55.0    192.168.101.201 255.255.255.192 UG    0      0        0 tunl0 # 当ping 包来到node02上会匹配到这条路由tunl0, 该路由的意思是: 去往 172.173.55.0/26 的网段的数据包都发往 网关 192.168.101.201上。因为pod2在101.202上，pod1在101.201上，所以数据包会通过设备tunl0发送到101.201上，也就是node01上。
192.168.101.0   0.0.0.0         255.255.255.0   U     0      0        0 ens33

```

### 1.3 node01上查看

```shell

# 查看node01上路由信息
[root@node01 ~]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.101.1   0.0.0.0         UG    0      0        0 ens33
169.254.0.0     0.0.0.0         255.255.0.0     U     1002   0        0 ens33
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
172.165.231.128 192.168.101.202 255.255.255.192 UG    0      0        0 tunl0
172.171.205.128 192.168.101.100 255.255.255.192 UG    0      0        0 tunl0
172.173.55.0    0.0.0.0         255.255.255.192 U     0      0        0 *
172.173.55.45   0.0.0.0         255.255.255.255 UH    0      0        0 cali099f6bce604 # 当node01网卡收到数据包之后，发现发往目的地ip为172.173.55.45，匹配到此时这条路由，该路由的意思: 172.173.55.45是本机直连路由，去往设备的数据包发往 cali099f6bce604，此cali099f6bce604 设备是veth 对的一端
192.168.101.0   0.0.0.0         255.255.255.0   U     0      0        0 ens33

# 从master上可以查到pod1上的网卡 veth 对另一端的设备号是9
[root@node01 ~]# ip a
...
9: cali099f6bce604@if4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1440 qdisc noqueue state UP group default 
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link 
       valid_lft forever preferred_lft forever  # 也就是这个网卡，可以看到此网卡就是  cali099f6bce604

# 到此ping 结束。

```

## 2. IPIP和BGP

IPIP替换成BGP(未进行测试):
```shell
vim calico.yaml

- name: CALICO_IPV4POOL_IPIP
              value: "off"

# 在安装calico网络时，默认安装是IPIP网络。calico.yaml文件中，将CALICO_IPV4POOL_IPIP的值修改成 "off"，就能够替换成BGP网络
```

IPIP模式:
pod1---tunl0---ens160 ------------------- ens160---tunl0---pod2


BGP模式:
pod1---ens160 ---------------- ens160---pod2


## 3. 比较
IPIP网络：
流量：tunlo设备封装数据，形成隧道，承载流量。
适用网络类型：适用于互相访问的pod不在同一个网段中，跨网段访问的场景。外层封装的ip能够解决跨网段的路由问题。
效率：流量需要tunl0设备封装，效率略低

BGP网络：
流量：使用路由信息导向流量
适用网络类型：适用于互相访问的pod在同一个网段，适用于大型网络。
效率：原生hostGW，效率高

## 4. 问题
(1) 缺点租户隔离问题
Calico 的三层方案是直接在 host 上进行路由寻址，那么对于多租户如果使用同一个 CIDR 网络就面临着地址冲突的问题。

(2) 路由规模问题
通过路由规则可以看出，路由规模和 pod 分布有关，如果 pod离散分布在 host 集群中，势必会产生较多的路由项。

(3) iptables 规则规模问题
1台 Host 上可能虚拟化十几或几十个容器实例，过多的 iptables 规则造成复杂性和不可调试性，同时也存在性能损耗。

(4) 跨子网时的网关路由问题
当对端网络不为二层可达时，需要通过三层路由机时，需要网关支持自定义路由配置，即 pod 的目的地址为本网段的网关地址，再由网关进行跨三层转发