[toc]

## 1. 保持pod健康

使用RC或者DaemonSet控制器创建pod的好处:
当pod所在的工作节点失败后，pod容器可以在其他节点上重新被控制器创建，直接创建pod没有这个功能。


### 1.1 介绍存活探针
K8S可以通过存活探针(liveness probe) 检查容器是否还在运行。可以为pod中的每个容器单独指定存活探针。如果探测失败，k8s将定期执行探针并重新启动容器。

k8s由以下三种探测容器机制:
1. HTTP GET 探针对容器的IP地址(你指定的端口和路径)执行HTTP GET 请求。如果探测器收到响应，并且响应状态码不代表错误(HTTP返回的状态码是2xx或者是3xx)，则认为探测成功。如果服务器返回错误响应状态码或者根本没响应，那么探测认为是失败的，容器将被重新启动。
2. TCP套接字探针尝试与容器指定端口建立TCP连接，如果连接成功建立，则探测成功，否则失败，容器重新启动。
3. Exec 探针在容器内执行任意命令，并检查命令的退出状态码，如果状态码是0，表示探测成功。所有其他状态码都被认为失败。

### 1.2 创建基于HTTP的存活探针

演示基于HTTP的存活探针，新的应用wanstack/kubia-unhealthy 镜像会启动一个web应用程序，前5个请求正常响应，第5个请求后会返回500的内部错误，这个时候 存活探针可以帮助我们重启应用。

举例:
vim kubia-liveness-probe.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-liveness
spec:
  containers:
  - image: wanstack/kubia-unhealthy  # 这是个测试镜像，第5个请求后返回500错误
    name: kubia
    livenessProbe:   # 一个HTTP GET的存活探针
      httpGet:
        path: /  # http请求路径
        port: 8080  # 探针连接的网络端口
```
该pod的描述文件定义了一个httpGet 存活探针，该探针告诉k8s定期在端口8080上执行http get请求，以确定容器是否健康，这些请求在容器启动后立即开始。

### 1.3 使用存活探针

```shell
# 创建上面的pod
k apply -f kubia-liveness-probe.yaml

# 查看创建的pod
[root@master 04]# k get pod kubia-liveness 
NAME             READY   STATUS    RESTARTS   AGE
kubia-liveness   1/1     Running   3          8m36s

# 其中 RESTARTS 列表示pod的容器已经被重启3次。

# 获取崩溃容器的应用日志
# k logs 表示获取当前容器的日志，当你想看到前一个容器的日志时可以使用 --previous选项
k logs kubia-liveness --previous 

# 可以使用describe 获取更多信息
[root@master 04]# k describe pod kubia-liveness 
Name:         kubia-liveness
Namespace:    default
Priority:     0
Node:         node02/192.168.101.202
Start Time:   Fri, 08 Oct 2021 18:30:07 +0800
Labels:       <none>
Annotations:  <none>
Status:       Running
IP:           172.165.231.153
IPs:
  IP:  172.165.231.153
Containers:
  kubia:
    Container ID:   docker://7c6d47da1ff1cebaacce87c1e81018a7896bb27f306f1086e112510f5735bbb9
    Image:          wanstack/kubia-unhealthy
    Image ID:       docker-pullable://wanstack/kubia-unhealthy@sha256:5c746a42612be61209417d913030d97555cff0b8225092908c57634ad7c235f7
    Port:           <none>
    Host Port:      <none>
    State:          Running  # 表示容器正在运行
      Started:      Fri, 08 Oct 2021 18:44:03 +0800
    Last State:     Terminated  # 先前的错误，由于发生错误被终止，返回码时137
      Reason:       Error
      Exit Code:    137  # 137 表示128 + 9 ，9表示SIGKILL的信号编号，意味着这个进程被强制终止。
      Started:      Fri, 08 Oct 2021 18:42:03 +0800
      Finished:     Fri, 08 Oct 2021 18:43:47 +0800
    Ready:          True
    Restart Count:  6  # 该容器已经被重启了6次了
    Liveness:       http-get http://:8080/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-vn2b5 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-vn2b5:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age                   From               Message
  ----     ------     ----                  ----               -------
  Normal   Scheduled  14m                   default-scheduler  Successfully assigned default/kubia-liveness to node02
  Normal   Pulled     13m                   kubelet            Successfully pulled image "wanstack/kubia-unhealthy" in 1m22.530333172s
  Normal   Pulled     10m                   kubelet            Successfully pulled image "wanstack/kubia-unhealthy" in 34.339765801s
  Normal   Created    8m43s (x3 over 13m)   kubelet            Created container kubia
  Normal   Started    8m43s (x3 over 13m)   kubelet            Started container kubia
  Normal   Pulled     8m43s                 kubelet            Successfully pulled image "wanstack/kubia-unhealthy" in 22.971960407s
  Normal   Killing    7m26s (x3 over 11m)   kubelet            Container kubia failed liveness probe, will be restarted
  Normal   Pulling    6m56s (x4 over 14m)   kubelet            Pulling image "wanstack/kubia-unhealthy"
  Normal   Pulled     6m40s                 kubelet            Successfully pulled image "wanstack/kubia-unhealthy" in 15.255633868s
  Warning  Unhealthy  3m46s (x13 over 12m)  kubelet            Liveness probe failed: HTTP probe failed with statuscode: 500

# 最后一行显示 HTTP GET 存活探针, k8s发现容器不健康，所以终止并重新创建。
# 当容器被强行终止时，会创建一个全新的容器，而不是重启原来的容器
```

### 1.4 配置存活探针的附加属性

在1.3的输出中有
```shell
Liveness:       http-get http://:8080/ delay=0s timeout=1s period=10s #success=1 #failure=3
```
- delay: 延迟，delay=0s表示在容器启动后立即开始探测。
- timeout: 超时，timeout=1s表示容器必须在1s内进行响应，否则视作探测失败。
- period: 间隔，period=10s表示每10s探测一次容器，并在连续探测3次失败(failure=3)后重启容器。sucesses=1表示1次探测成功表示探测成功。

定义探针时可以自定义上述属性。delay - initialDelaySeconds
vim kubia-liveness-probe-initial-delay.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-liveness-init-delay
spec:
  containers:
  - image: wanstack/kubia-unhealthy  # 这是个测试镜像，第5个请求后返回500错误
    name: kubia
    livenessProbe:   # 一个HTTP GET的存活探针
      httpGet:
        path: /  # http请求路径
        port: 8080  # 探针连接的网络端口
      initialDelaySeconds: 15   # k8s会在第一次探测前等待15秒
```

```shell
k apply -f kubia-liveness-probe-initial-delay.yaml

[root@master 04]# k describe pod kubia-liveness-init-delay 
Name:         kubia-liveness-init-delay
Namespace:    default
Priority:     0
Node:         node02/192.168.101.202
Start Time:   Fri, 08 Oct 2021 19:56:51 +0800
Labels:       <none>
Annotations:  <none>
Status:       Running
IP:           172.165.231.154
IPs:
  IP:  172.165.231.154
Containers:
  kubia:
    Container ID:   docker://ebd7f21b73d01d61042c2fe7c82423aee3cd45d2b25c189f2212e7a987ce7649
    Image:          wanstack/kubia-unhealthy
    Image ID:       docker-pullable://wanstack/kubia-unhealthy@sha256:5c746a42612be61209417d913030d97555cff0b8225092908c57634ad7c235f7
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Fri, 08 Oct 2021 19:56:58 +0800
    Ready:          True
    Restart Count:  0
    Liveness:       http-get http://:8080/ delay=15s timeout=1s period=10s #success=1 #failure=3

# initialDelaySeconds  delay参数默认为0，探针将在启动时立即开始探测容器，通常容器中的应用程序还没准备好接受请求，导致探测失败，如果失败次数超过阈值，容器中的应用程序可以正常响应请求之前，容器会重新创建。所以必须得设置一个初始延迟来说明应用程序启动时间。
```

### 1.5 创建有效的存活探针
对于生产中的pod，必须定义一个存活探针，没有探针k8s没办法直到你的应用是否还存活，只要进程还在运行k8s会认为容器时健康的。


1. 存活探针检查什么
对于探针检测，最好时配置特定的URL路径，比如/health 并让应用从内部对内部运行的所有重要组件执行状态检查，确保他们没有终止或者停止响应。
>> 确保 /health HTTP端点不需要认证，否则探测会一直失败，导致容器无限重启。

存活探针对于前端检查和后端检查分开进行，比如当服务器无法连接到数据库时，前端web服务器检测不应该失败。因为如果是后端数据库导致，重启web服务器解决不了问题。

2. 保持探针轻量
存活探针不应该消耗太多的计算资源，并且运行不应该花费太长时间，默认情况下，探测器执行的频率相对较高，必须在1秒内执行完毕。探针的CPU时间计入容器CPU时间配额，如果使用重量级的存活探针将减少主应用程序进程可用的CPU时间。

>> 如果你在容器中运行java应用程序，请确保使用HTTP GET 存活探针，而不是启动全新JVM以获取存活信息的Exec探针，任何基于JVM或类似的应用程序也是如此，他们启动过程需要大量的计算资源。

3. 无需在探针中实现重试循环
探针失败阈值时可配置的


## 2. ReplicationController控制器

RC是k8s的一种资源，可确保pod始终保持运行状态，如果pod因任何原因消失(例如节点从集群中消失或由于该pod已从节点中逐出)
则RC会注意到缺少的pod并创建替代的pod。

### 2.1 ReplicationController操作

1. RC组成：
- label selector(标签选择器): 用于确定RC作用域中有那些pod
- replica count(副本个数): 指定应运行的pod数量
- pod template(pod模板): 用于创建新的pod副本

2. 更改控制器的标签选择器或pod模板的效果
更改控制器啊的标签选择器会使现有的pod脱离RC的范围，因此RC会停止关注他们。更改pod模板不会影响现有pod，但是新创建的pod会使用新的pod模板。

3. 使用RC的好处
- 确保一个pod(或多个pod副本)持续运行，方法是现有pod丢失时启动一个新的pod
- 集群的工作节点故障时，RC将为故障节点上运行的pod(即受到RC控制器的节点上的pod)创建替代副本
- 轻松实现pod的扩缩容 --- 手动和自动都可以


### 2.2 创建一个ReplicationController

vim kubia-rc.yaml
```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: kubia
spec:
  replicas: 3   # pod实例的目标数目
  selector:    # pod 的选择器决定了RC操作的作用域，标签选择器
    app: kubia
  template:
    metadata:
      labels:
        app: kubia
    spec:
      containers:
      - name: kubia
        image: wanstack/kubia
        ports:
        - containerPort: 8080
```
> 1. 确保标签选择器app=kubia的pod实例始终是3个，当没有足够的pod时，根据提供的pod模板创建新的pod。
> 2. 模板中的pod的标签必须和RC的标签选择器匹配，否则控制器RC会无休止的创建新的容器。因为启动新pod不会使实际的副本数量接近期望的副本数量，为了防止这种情况，k8s 的API服务会校验RC的定义，不会接收错误的配置。
> 3. 根本不指定选择器也是一种选择，在这种情况下，他会自动根据pod模板中的标签自动配置。

### 2.3 使用ReplicationController

```shell
# 创建
k apply -f kubia-rc.yaml

# 根据上述kubia-rc.yaml 会创建3个pod，并且标签app=kubia
[root@master 04]# k get pod -o wide --show-labels 
NAME          READY   STATUS    RESTARTS   AGE   IP              NODE     NOMINATED NODE   READINESS GATES   LABELS
kubia-5d22f   1/1     Running   0          15m   172.173.55.34   node01   <none>           <none>            app=kubia
kubia-6h4wc   1/1     Running   0          15m   172.173.55.33   node01   <none>           <none>            app=kubia
kubia-t7n6n   1/1     Running   0          15m   172.173.55.32   node01   <none>           <none>            app=kubia

# 删除其中一个pod，会创建一个新的pod，始终运行3个相应的pod
# 关机node01，相应的pod会在node02上创建，时间比较慢大概需要5分钟左右。

[root@master 04]# k get rc -o wide
NAME    DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES           SELECTOR
kubia   3         3         3       29m   kubia        wanstack/kubia   app=kubia

# 其中 DESIRED 表示期望的pod数量，CURRENT 表示当前pod数量，READY就绪的pod的数量

[root@master 04]# k describe rc kubia 
Name:         kubia
Namespace:    default
Selector:     app=kubia
Labels:       app=kubia
Annotations:  <none>
Replicas:     3 current / 3 desired  # pod的实际数量和目标数量
Pods Status:  3 Running / 0 Waiting / 0 Succeeded / 0 Failed  # 每种状态下pod的数量
Pod Template:
  Labels:  app=kubia
  Containers:
   kubia:
    Image:        wanstack/kubia
    Port:         8080/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:  # 和RC有关系的事件
  Type    Reason            Age   From                    Message
  ----    ------            ----  ----                    -------
  Normal  SuccessfulCreate  30m   replication-controller  Created pod: kubia-tld84
  Normal  SuccessfulCreate  30m   replication-controller  Created pod: kubia-lk8n9
  Normal  SuccessfulCreate  30m   replication-controller  Created pod: kubia-rktw8
  Normal  SuccessfulCreate  21m   replication-controller  Created pod: kubia-t7n6n
  Normal  SuccessfulCreate  21m   replication-controller  Created pod: kubia-5d22f
  Normal  SuccessfulCreate  21m   replication-controller  Created pod: kubia-6h4wc

```

### 2.4 将pod移入或移出ReplicationController的作用域
```shell
# 查看pod所属的RC
[root@master 04]# k get pod kubia-t7n6n -o yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2021-10-08T16:36:25Z"
  generateName: kubia-
  labels:
    app: kubia
  name: kubia-t7n6n
  namespace: default
  ownerReferences:
  - apiVersion: v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicationController
    name: kubia  # 从这里可以看出此 pod 属于 kubia的RC控制器
    uid: 6076d287-52c6-4f01-8f08-ed2853395bc7
  resourceVersion: "1632329"
  uid: 14774565-4610-478c-b796-d1fa6d895ecf
...

# 更改pod的标签，会使此pod从RC中移除，RC不在关注此pod，需要注意的是更改其中一个或者多个pod，RC会重新创建app=kubia的pod，直到个数和之前定义的相等

# 更改标签需要加上 --overwrite
[root@master 04]# k label pod kubia-t7n6n app=foo --overwrite 
pod/kubia-t7n6n labeled
[root@master 04]# k get pod
NAME                        READY   STATUS              RESTARTS   AGE
kubia-5d22f                 1/1     Running             0          50m
kubia-6h4wc                 1/1     Running             0          50m
kubia-liveness              1/1     Running             10         34m
kubia-liveness-init-delay   0/1     CrashLoopBackOff    10         34m
kubia-qkbwl                 0/1     ContainerCreating   0          3s
kubia-t7n6n                 1/1     Running             0          50m
# 可以看到 RC 又创建了一个新的pod，并且打上标签app=kubia
[root@master 04]# k get pod --show-labels 
NAME                        READY   STATUS             RESTARTS   AGE   LABELS
kubia-5d22f                 1/1     Running            0          50m   app=kubia
kubia-6h4wc                 1/1     Running            0          50m   app=kubia
kubia-liveness              1/1     Running            10         34m   <none>
kubia-liveness-init-delay   0/1     CrashLoopBackOff   10         34m   <none>
kubia-qkbwl                 1/1     Running            0          12s   app=kubia
kubia-t7n6n                 1/1     Running            0          50m   app=foo
```

1. 从控制器中删除pod
当你想操作特定的 pod 时， 从 ReplicationController 管理范围中移除 pod 的操作很管用。
例如，你可能有一个 bug 导致你的 pod 在特定时间或特定事件后开始出问题。如果你知道某个 pod 发生了故障， 就可以将它从 Replication-Controller 的管理范围中移除， 让控制器将它替换为新 pod, 接着这个 pod 就任你处置了。 完成后删除该pod 即可。


### 2.5 修改pod模板

```shell
# 更改pod模板，有些参数修改完成后立即生效，例如 spec.replicas: 5，有些参数不能立即生效，例如spec.template.spec.containers.image
k edit rc kubia 

# 此方法可以用来升级
```

### 2.6 水平缩放pod

```shell
# 扩容到10个pod， 也可以使用 k edit rc kubia 手动更改 spec.replicas: 10
k scale rc kubia --replicas=10

# 缩容到2个pod
k scale rc kubia --replicas=2

# 此处可以看到 k8s 是声明式的，不是告诉k8s集群我需要扩容或者缩容pod，而是我想要多少个pod，这种方式很容器理解并且实现
```


### 2.7 删除一个ReplicationController
```shell
# 删除rc时，默认rc管理的pod也会被一起删除，也可以只删除rc并保持pod运行。
# 比如使用ReplicaSet替换RC时，仅仅删除RC，保留pod被RS托管就很有用
[root@master 04]# k delete rc kubia --cascade=false  # 删除rc时保留pod
warning: --cascade=false is deprecated (boolean value) and can be replaced with --cascade=orphan.
replicationcontroller "kubia" deleted
[root@master 04]# k get pod
NAME                        READY   STATUS             RESTARTS   AGE
kubia-5d22f                 1/1     Running            0          118m
kubia-6h4wc                 1/1     Running            0          118m
kubia-liveness              1/1     Running            25         101m
kubia-liveness-init-delay   0/1     CrashLoopBackOff   24         101m

```

## 3. RelicaSet代替ReplicationController

### 3.1 比较ReplicaSet和ReplicationController

RS比RC关于pod选择器的表达能力更强，RS的选择器允许匹配缺少某个标签的pod(取反)，包含某个特定标签名的pod，不管其值如何(env=*), RC只能匹配标签env1=pro或者env2=devel, 但是RS可以匹配env1=pro和env2=devel(且)

### 3.2 定义ReplicaSet
在2.7


### 3.3 使用ReplicaSet的更富表达力的标签选择器

### 3.4 ReplicaSet小结


## 4. DaemonSet在每个节点上运行一个pod



## 5. 运行执行单个任务的pod



## 6. 安排Job定期运行或在将来运行一次