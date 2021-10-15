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
在kube-system命名空间下，又一个

3. 通过FQDN连接服务

4. 在pod容器中运行shell

5. 无法ping通服务IP地址的原因

## 2. 连接集群外部的服务


## 3. 将服务暴露给外部客户端


## 4. 通过Ingress暴露服务


## 5. pod就绪后发出信号


## 6. 使用headless服务来发现独立的pod


## 7. 排除服务故障

## 8. 本章小结