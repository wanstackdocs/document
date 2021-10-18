[toc]

## 1. 介绍服务

pod需要响应来自集群内部的其他pod，以及来及集群外部客户端的HTTP请求做出响应。

在没有k8s世界中，通常系统管理员需要在用户端配置文件中明确指出服务的精确IP地址或者主机名来配置每个客户端的应用。这在k8s中是不适用的，因为:
1. pod是短暂的 -- 他们随时会启动或者关闭，无论是为了给其他pod提供空间而从节点中被移除，或者是减少pod的数量，又或者集群中存在异常节点。
2. k8s在pod启动前会给已经调度到节点上的pod分配IP地址 -- 因此客户端不能提前知道提供服务的pod的IP地址。
3. 水平伸缩意味着多个pod可能会提供相同的服务 -- 每个pod都有自己的IP地址，客户端无需关心后端提供服务pod的数量，相反，所有的pod可以通过一个单一的IP地址进行访问。

为了解决上述的问题，k8s提供了一种资源类型 -- 服务(service)

### 1.1 创建服务
除了使用k expose命令之外， k expose rc kubia --type=NodePort --name kubia-http 也可以使用yaml

vim kubia-svc.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia
spec:
  ports:
  - port: 80  # 该服务可用的端口
    targetPort: 8080  # 服务将连接转发到的容器端口
  selector:
    app: kubia  # 具有app=kubia 标签的pod都属于该服务
```
创建了一个名叫kubia的服务，它将在80端口接受请求，并将连接 路由到具有标签选择器是app=kubia的pod的8080端口上。

1. 检测新的服务
```shell
[root@master 05]# k get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   192.168.0.1      <none>        443/TCP   12d
kubia        ClusterIP   192.168.77.121   <none>        80/TCP    5s

# 列表显示分配的IP地址是 192.168.77.121 ，因为只是集群的IP地址，只能在集群内部被访问。服务的主要目标是使集群内部的其他pod可以访问当前这组pod，但是也希望对外提供服务，这在之后实现。
```

2. 从内部集群测试服务
有以下几种方式向服务发送请求:
- 创建一个新pod，它将请求发送到服务的集群IP并记录响应，可以通过查看pod的日志检查服务的响应。
- 使用ssh 登录到其中一个k8s节点上，然后执行curl命令
- 可以通过kubectl exec 命令在一个已经存在的pod中执行curl命令

3. 在运行的容器中远程执行命令
```shell
[root@master 05]# k get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   192.168.0.1      <none>        443/TCP   12d
kubia        ClusterIP   192.168.77.121   <none>        80/TCP    5s
[root@master 05]# k get pod
NAME                                             READY   STATUS      RESTARTS   AGE
batch-job-every-fifteen-minites-27232740-g7kqx   0/1     Completed   0          12m
kubias-nmjlr                                     1/1     Running     0          18m
kubias-p7wv5                                     1/1     Running     0          18m
kubias-q2h4p                                     1/1     Running     0          18m
You have new mail in /var/spool/mail/root
[root@master 05]# k exec kubias-nmjlr -- curl -s http://192.168.77.121
Youve hit kubias-q2h4p

# 关于双横杠 -- 解释: -- 代表着 kubectl命令的结束，后面的内容指的是 在pod内部执行的命令
```

在一个pod容器上，利用k8s执行curl 命令，curl命令curl命令service发送一个HTTP请求，service通过IPVS 随机(轮询算法)选择一个pod进行响应。

4. 配置服务上的会话亲和性
如果多次执行上述命令，每次调用应该在不同的pod上，如果希望 针对特定客户端产生的所有请求每次都指向同一个pod，可以设置服务的sessionAffinity属性未ClientIP(而不是None, None是默认值)

vim kubia-svc02.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia02
spec:
  sessionAffinity: ClientIP
  ports:
  - port: 80  # 该服务可用的端口
    targetPort: 8080  # 服务将连接转发到的容器端口
  selector:
    app: kubia  # 具有app=kubia 标签的pod都属于该服务
```

```shell
[root@master 05]# k get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   192.168.0.1      <none>        443/TCP   12d
kubia        ClusterIP   192.168.77.121   <none>        80/TCP    18h
kubia02      ClusterIP   192.168.18.136   <none>        80/TCP    16h
You have new mail in /var/spool/mail/root
[root@master 05]# k get pod
NAME           READY   STATUS    RESTARTS   AGE
kubias-nmjlr   1/1     Running   1          18h
kubias-p7wv5   1/1     Running   1          18h
kubias-q2h4p   1/1     Running   1          18h
[root@master 05]# k exec kubias-p7wv5 -- curl -s http://192.168.18.136
You've hit kubias-p7wv5
[root@master 05]# k exec kubias-p7wv5 -- curl -s http://192.168.18.136
You've hit kubias-p7wv5
[root@master 05]# k exec kubias-p7wv5 -- curl -s http://192.168.18.136
You've hit kubias-p7wv5
[root@master 05]# k exec kubias-p7wv5 -- curl -s http://192.168.18.136
You've hit kubias-p7wv5
[root@master 05]# k exec kubias-p7wv5 -- curl -s http://192.168.18.136
You've hit kubias-p7wv5
[root@master 05]# k exec kubias-p7wv5 -- curl -s http://192.168.18.136
You've hit kubias-p7wv5
[root@master 05]# k exec kubias-p7wv5 -- curl -s http://192.168.18.136
You've hit kubias-p7wv5
[root@master 05]# k exec kubias-p7wv5 -- curl -s http://192.168.18.136
You've hit kubias-p7wv5

# 将来自同一个client IP的所有请求转发至同一个pod上，
```

5. 同一个服务暴露多个端口
创建服务可以暴露一个端口，也可以暴露多个端口。例如一个pod监听2个端口，一个8080，一个8443，可以通过一个集群IP，一个服务可以将多个服务端口全部暴露出来
> 在创建一个有多个端口的时候，必须给每个端口指定名字
vim kubia-multiport-svc.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-multiport-svc
spec:
  ports:
  - name: http  # pod 的8080端口映射为80端口
    port: 80
    targetPort: 8080  
  - name: https
    port: 443
    targetPort: 8443
  selector:  # 标签选择器适用于整个服务
    app: kubia
```


6. 使用命名的端口
之前的例子是通过数字来指定端口，但是在服务的spec中也可以给不同的端口号命名，通过名称来指定。

```yaml
apiVersion: v1
kind: Pod
metadata: 
  name: kubia-port
spec:
  containers:
  - name: kubia
    image: wanstack/kubia
    ports:
    - name: http  # 端口8080被命名为http
      containerPort: 8080 
    - name: https # 端口8443被命名为https
      containerPort: 8443  
```
上述的端口名称可以被svc引用
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-name-port
spec:
  ports:
  - name: http  # 将端口80 映射到容器中被称为http的端口
    port: 80
    targetPort: http
  - name: https # 将端口443 映射到容器中被称为https的端口
    port: 443
    targetPort: https
  selector:
    app: kubia
```
使用命名端口的好处是即使pod那边更换端口号，无需更改服务的spec，比如你的pod现在监听的是8080端口，过段时间换成了80端口，这个时候仅仅只需要更改spec pod的端口号。

### 1.2 服务发现
服务发现pod，是依靠标签选择器。但是pod发现服务是通过什么？

通过创建服务现在可以通过一个单一稳定的IP地址访问到pod了，在服务的生命周期这个地址保持不变，服务后面的pod可能会删除重建，pod的IP地址可能会改变，数量可能增减，但是始终可以通过单一的服务的IP访问到这个pod。

但是客户端pod如果知道服务的IP和端口，是否需要事先创建服务，然后查询出服务的IP和端口，然后手动配置客户端pod的配置文件。当然不是，k8s提供了一套发现服务IP地址和端口的方式。

1. 通过环境变量发现服务
首先必须先创建服务，再创建pod，然后pod运行的时候，k8s会初始化一系列的环境变量指向现在存在的服务。
如果先创建pod，再创建服务则不会。
```shell
[root@master 03]# k get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   192.168.0.1      <none>        443/TCP   15d
kubia        ClusterIP   192.168.77.121   <none>        80/TCP    3d1h
[root@master 03]# k get pod
NAME           READY   STATUS    RESTARTS   AGE
kubias-6kptt   1/1     Running   0          62s
kubias-6wrt6   1/1     Running   0          62s
kubias-9xqf6   1/1     Running   0          62s
[root@master 03]# k exec kubias-9xqf6 env
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=kubias-9xqf6
KUBERNETES_PORT=tcp://192.168.0.1:443
KUBIA_SERVICE_PORT=80 # 服务的端口
KUBIA_PORT_80_TCP=tcp://192.168.77.121:80
KUBERNETES_SERVICE_HOST=192.168.0.1
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT_443_TCP=tcp://192.168.0.1:443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP_PORT=443
KUBIA_PORT=tcp://192.168.77.121:80
KUBIA_PORT_80_TCP_PROTO=tcp
KUBIA_PORT_80_TCP_PORT=80
KUBERNETES_SERVICE_PORT=443
KUBERNETES_PORT_443_TCP_ADDR=192.168.0.1
KUBIA_SERVICE_HOST=192.168.77.121 # 服务的IP地址
KUBIA_PORT_80_TCP_ADDR=192.168.77.121
NPM_CONFIG_LOGLEVEL=info
NODE_VERSION=7.10.1
YARN_VERSION=0.24.4
HOME=/root

# 可以看到先创建服务，再创建pod，可以在pod内部的环境变量中看到服务的IP和端口，这有什么用呢？

# 想象一下，前端的pod需要连接后端服务的IP，可以确定的是后端的服务名称是backend-database, 前端的pod怎么连接后端的服务呢？ 可以通过连接 BACKEND_DATABASE_SERVICE_HOST 和 BACKEND_DATABASE_SERVICE_PORT 去获取后端服务的IP地址和port。
# 这里需要注意的是: 后端服务的名称是中横线 - , 但是在pod内部环境变量显示的就是 大写+下划线  _
```

2. 通过DNS发现服务
在kube-system命名空间下，有一个名为 coredns 开头的pod(可能不止一个)，其对应的service就是其他pod的dns server地址。
```shell
[root@master 05]# k get svc -n kube-system 
NAME       TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   192.168.0.10   <none>        53/UDP,53/TCP,9153/TCP   25d
[root@master 05]# k get endpoints -n kube-system 
NAME       ENDPOINTS                                                              AGE
kube-dns   172.171.205.159:53,172.171.205.160:53,172.171.205.159:53 + 3 more...   25d  # 查看service对应的pod地址
[root@master 05]# k get pod -n kube-system -o wide
NAME                                      READY   STATUS    RESTARTS   AGE   IP                NODE     NOMINATED NODE   READINESS GATES
calico-kube-controllers-cdd5755b9-dm2cv   1/1     Running   14         24d   192.168.101.100   master   <none>           <none>
calico-node-8mczc                         1/1     Running   19         25d   192.168.101.202   node02   <none>           <none>
calico-node-qzgvz                         1/1     Running   19         25d   192.168.101.100   master   <none>           <none>
calico-node-r4nvp                         1/1     Running   17         25d   192.168.101.201   node01   <none>           <none>
coredns-6f6b8cc4f6-v4t56                  1/1     Running   16         25d   172.171.205.159   master   <none>           <none> # 这个是dns server service的pod
coredns-6f6b8cc4f6-wrlht                  1/1     Running   14         24d   172.171.205.160   master   <none>           <none> # 这个是dns server service的pod

# 随便找一个pod，看一下其dns server的地址
[root@master 05]# k exec kubias-6kptt -- cat /etc/resolv.conf 
nameserver 192.168.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5

```

3. 通过FQDN连接服务

前端pod可以通过服务的名称访问后端的service。比如
```shell
[root@master 05]# k get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   192.168.0.1      <none>        443/TCP   18d
kubia        ClusterIP   192.168.77.121   <none>        80/TCP    6d18h

# 具体的service 端口可以从pod 的环境变量中回去
[root@master 05]# k exec kubias-9xqf6 -- curl -s http://kubia.default.svc.cluster.local
Youve hit kubias-6wrt6

# 如果前端的pod和后端的pod在同一个命名空间下，可以省略.default.svc.cluster.local 直接使用服务的名字kubia即可。

```

4. 在pod容器中运行shell
```shell
# 进入到pod容器中
[root@master 05]# k exec -ti kubias-9xqf6 bash
# 在pod容器中执行shell命令
root@kubias-9xqf6:/# cat /etc/resolv.conf 
nameserver 192.168.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
root@kubias-9xqf6:/# ping kubia
PING kubia.default.svc.cluster.local (192.168.77.121): 56 data bytes
64 bytes from 192.168.77.121: icmp_seq=0 ttl=64 time=0.034 ms
^C--- kubia.default.svc.cluster.local ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max/stddev = 0.034/0.034/0.034/0.000 ms

```

## 2. 连接集群外部的服务

### 2.1 介绍服务的endpoint
服务不是和pod直接连接的，中间还存在Endpoint。
```shell
[root@master 05]# k describe svc kubia 
Name:              kubia
Namespace:         default
Labels:            <none>
Annotations:       <none>
Selector:          app=kubia  # 用于创建endpoint列表的服务pod选择器
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                192.168.77.121
IPs:               192.168.77.121
Port:              <unset>  80/TCP
TargetPort:        8080/TCP
Endpoints:         172.165.231.182:8080,172.165.231.183:8080,172.173.55.53:8080 # 代表服务endpoint的pod的ip和端口列表
Session Affinity:  None
Events:            <none>

# endpoint资源就是暴露一个服务的IP地址和端口列表
[root@master 05]# k get endpoints 
NAME         ENDPOINTS                                                      AGE
kubernetes   192.168.101.100:6443                                           18d
kubia        172.165.231.182:8080,172.165.231.183:8080,172.173.55.53:8080   6d19h

# spec服务中定义了pod选择器，选择器用于构建IP地址和端口列表，然后存储在endpoint资源中。当客户端连接服务时，服务代理选择这些IP和端口中的一个，并将传入的连接重定向到在该位置监听的服务器。
```

### 2.2 手动配置服务的endpoint
服务和endpoint解耦后，可以分别手动配置和更新他们。
如果创建了 不包含 pod选择器的服务，k8s将不会创建endpoint资源(缺少选择器，服务也不知道服务中包含哪些pod)，这样就需要创建endpoint资源来指定该服务的endpoint列表。

1. 创建没有选择器的服务

>一般用于外部IP提供的服务

vim external-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-service  # 服务的名字必须和Endpoint对象的名称相同
spec:  # 服务中没有定义选择器
  ports:
  - port: 80
```
定义一个名为external-service的服务，它将接收端口80上传入的连接，并没有为服务定义一个pod选择器。

2. 为没有选择器的服务创建Endpoint资源
Endpoint是k8s单独的一个资源，并不是服务的一个属性，由于创建的资源中并不包含选择器，相关的Endpoint资源并没有自动创建，所以必须手动创建。
vim external-service-endpoint.yaml
```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: external-service # 这个名称必须和 1 中的名称一样
subsets:
  - addresses:  # 服务将连接重定向到endpoint的IP地址
    - ip: 172.165.231.185   # 这里也可以是独立于k8s之外的IP
    - ip: 172.165.231.184   # 这里也可以是独立于k8s之外的IP
    ports:
    - port: 80  # endpoint的目标端口
```
Endpoint对象需要与服务具有相同的名称 external-service , 并且包含服务的目标IP地址列表和端口列表。服务和endpoint资源都发布到服务后，这样服务就可以像具有pod选择器那样的服务正常使用。在服务创建后创建的容器将包含服务的环境变量，并且与其IP:PORT 对 的所有连接都将在服务端点之间进行负载均衡。
如果pod比service先创建，则不会有service的环境变量，需要删除pod重新创建pod。
```shell
# 删除所有的pod
k delete pod --all

# 查看pod的环境变量
[root@master 05]# k apply -f external-service-endpoint.yaml 
endpoints/external-service created
[root@master 05]# 
[root@master 05]# k get endpoints
NAME               ENDPOINTS                                                      AGE
external-service   172.165.231.185:80,172.165.231.184:80                          3s
kubernetes         192.168.101.100:6443                                           18d
kubia              172.165.231.184:8080,172.165.231.185:8080,172.173.55.54:8080   6d20h
[root@master 05]# k exec kubias-df4fg env
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=kubias-df4fg
KUBERNETES_PORT=tcp://192.168.0.1:443
KUBIA_SERVICE_HOST=192.168.77.121
EXTERNAL_SERVICE_SERVICE_HOST=192.168.87.22 # 这个是service的 host
KUBIA_PORT_80_TCP_ADDR=192.168.77.121
EXTERNAL_SERVICE_SERVICE_PORT=80 # 这个是service 的 port
EXTERNAL_SERVICE_PORT=tcp://192.168.87.22:80
EXTERNAL_SERVICE_PORT_80_TCP_PROTO=tcp
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBIA_PORT=tcp://192.168.77.121:80
KUBIA_PORT_80_TCP=tcp://192.168.77.121:80
EXTERNAL_SERVICE_PORT_80_TCP_PORT=80
KUBERNETES_SERVICE_PORT=443
KUBERNETES_PORT_443_TCP_ADDR=192.168.0.1
EXTERNAL_SERVICE_PORT_80_TCP=tcp://192.168.87.22:80
KUBERNETES_PORT_443_TCP_PORT=443
KUBIA_SERVICE_PORT=80
KUBIA_PORT_80_TCP_PROTO=tcp
KUBIA_PORT_80_TCP_PORT=80
EXTERNAL_SERVICE_PORT_80_TCP_ADDR=192.168.87.22
KUBERNETES_SERVICE_HOST=192.168.0.1
KUBERNETES_PORT_443_TCP=tcp://192.168.0.1:443
KUBERNETES_PORT_443_TCP_PROTO=tcp
NPM_CONFIG_LOGLEVEL=info
NODE_VERSION=7.10.1
YARN_VERSION=0.24.4
HOME=/root

```
手工管理service和endpoints资源仅仅是临时解决方案，最好还是自动管理比较方便一些。如果决定将外部服务迁移到k8s运行中的pod，可以为服务添加选择器，从而对Endpoints 进行自动管理。

### 2.3 为外部服务创建别名
在 2.2 手动配置服务的endpoint 是手动配置服务的Endpoint来代替公开外部服务的方法，还有一种更简单的方法，就是通过完全限定域名(FQDN) 访问外部服务。

1. 创建ExternalName类型的服务
要创建一个具有别名的外部服务的服务时，要将创建服务资源的一个type字段设置为ExternalName，例如 在 https://reqres.in/api/user?page=2 有公共可用的API，可以定义一个指向它的服务。
vim external-service-externalname.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-service
spec:
  type: ExternalName  # type 设置成ExternalName
  externalName: api.baidu.com  # 实际服务的完全限定域名
  ports:
  - port: 80
```

```shell
[root@master 05]# k get svc
NAME               TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)   AGE
external-service   ExternalName   <none>           api.baidu.com   80/TCP    42m
kubernetes         ClusterIP      192.168.0.1      <none>          443/TCP   18d
kubia              ClusterIP      192.168.77.121   <none>          80/TCP    6d20h
# 从上面的输出可以看到 不指定的默认是 ClusterIP，服务创建完成后，pod可以通过external-service.default.svc.cluster.info 域名(甚至是external-service)连接到外部服务器，而不是使用实际的api.baidu.com , 这隐藏了实际的服务名称，并且以后将其指向不同的服务，只需简单修改externalName属性，或者将类型重新变回ClusterIP并为服务创建Endpoint，无论是手动创建还是对服务上指定标签选择器使其自动创建。

```

## 3. 将服务暴露给外部客户端
目前为止，只讨论了在k8s集群内部如果被pod访问，但是还需要向外部公开某些访问，例如web服务器，以便外部客户端可以访问他们。
在外部访问服务的几种方式:
- 将服务的类型设置成NodePort -- 每个集群节点都会在打开一个端口(包括master节点), 对于NodePort服务，每个集群节点在节点本身上打开一个端口，并在将该端口上接收到的流量重定向到基础服务。该服务仅在集群内部IP和端口上才可以访问，但是也可以通过所有节点上的专有端口访问(映射应该是随机高端口)。
- 将服务的类型设置成LoadBalance -- NodePort类型的一种扩展，这使得服务可以通过专用的负载均衡器来访问，这是由k8s正在运行的云基础设施提供的，负载均衡器将流量重定向到跨所有节点的节点端口，客户端通过负载均衡器的IP地址连接到服务。(无法演示)
- 创建一个Ingress资源，这是一个完全不同的机制，通过一个IP地址公开多个服务 -- 它运行在HTTP层(第7层)，因此可以提供比工作在 第4层的服务更多的功能。

### 3.1 使用NodePort 类型的服务


### 3.2 通过负载均衡器将服务暴露出来

### 3.3 了解外部连接特性

## 4. 通过Ingress暴露服务

### 4.1 创建Ingress资源

### 4.2 通过Ingress访问服务

### 4.3 通过相同的Ingress暴露多个服务

### 4.4 配置Ingress处理TLS传输


## 5. pod就绪后发出信号


## 6. 使用headless服务来发现独立的pod


## 7. 排除服务故障

## 8. 本章小结