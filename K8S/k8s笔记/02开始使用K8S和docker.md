[toc]
## 1 在K8S上运行一个简单的应用

### 1.1 创建一个简单的Node.js 应用
构建一个简单的Node.js Web 应用，并把它打包到容器镜像中。 
这个应用会接收 HTTP 请求并响应应用运行的主机名。
这样，应用运行在容器中，看到的是自己的主机名而不是宿主机名，即使它也像其他进程一样运行在宿主机上。 
这在后面会非常有用，当应用部署在 Kubernetes 上并进行伸缩时（水平伸缩，复制应用到多个节点），你会发现 HTTP
请求切换到了应用的不同实例上 。应用包含一个名为 app.js 的文件。

vim app.js
```shell
const http = require('http');
const os = require('os');
console.log("Kubia server starting ... ");
var handler = function(request, response) {
    console.log("Received request from " + request.connection.remoteAddress);
    response.writeHead(200);
    response.end("You've hit " + os.hostname() + "\n");
}
var www = http.createServer(handler);
www.listen(8080);
```

代码清晰地说明了实现的功能。这里在 8080 端口启动了 一个 HTTP 服务器。服务器会以状态码 200 OK 和文字 
"You've hit <hostname>＂ 来响应每个请求 。请求 handler 会把客户端的 IP 打印到标准输出 ，以便日后查看。

### 1.2 构建容器镜像
为了把应用打包成镜像，首先需要创建一个叫 Dockerfile 的文件，它包含了一系列构建镜像日才会执行的指令 。 Dockerfile 文件需要和 app.js 文件在同一 目录，并包含下面代码清单中的命令。

Dockerfile
```shell
FROM node:7
ADD app.js /app.js
ENTRYPOINT ["node", "app.js"]
```

运行如下指令打包应用到镜像:
```shell
docker build -t kubia .
```

### 1.3 推送镜像到自己仓库中
```shell
# 给镜像打标签, 修改镜像tag kubia:latest 为 wanstack/kubia:latest
docker tag kubia wanstack/kubia:v1

# 推送镜像到仓库
docker push wanstack/kubia:v1
```

### 1.4 k8s创建pod
kubia-rc.yaml
```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: kubia
spec:
  replicas: 3
  selector:
    app: kubia
  template:
    metadata:
      labels:
        app: kubia
    spec:
      containers:
      - name: kubia
        image: wanstack/kubia:v1
        ports:
        - containerPort: 8080
```
解释:
一个ReplicationController有3个组成部分:
- label selector: 标签选择器, 用于确定RC 作用域中有那些pod
- replica count: 副本个数，指定应运行pod的数量
- pod template: pod 模板，用于创建新的pod副本

>- 确保符合标签选择器app=kubia的pod实例始终是三个。当没有足够的pod时，根据提供的pod模板创建 新的pod。
>- 模板中的pod标签显然必须和ReplicationController的标签选择器匹配，否则控制器将无休止地创建新的容器。
>- 因为启动新 pod不会使实际的副本数量接近期望的副本数量。
>- 为了防止出现这种情况，API服务会校验ReplicationController的定义，不会接收错误配置。
>- 根本不指定选择器也是一种选择。在这种情况下，它会自动根据pod模板中的标签自动配置。
>- 提示定义ReplicationController时不要指定pod选择器，让Kubemetes从pod模板中提取它。这样YAML更简短。

```shell
[root@master example_yaml]# k get pod  --show-labels 
NAME             READY   STATUS             RESTARTS   AGE   LABELS
fortune-config   1/2     CrashLoopBackOff   213        20h   <none>
kubia-n6szd      1/1     Running            0          16m   app=kubia
kubia-nrxc6      1/1     Running            0          16m   app=kubia
kubia-rxdr9      1/1     Running            0          16m   app=kubia
private-pod      1/1     Running            2          19h   <none>
其中LABELS列中 app=kubia 是pod template中定义的，标签选择器 app: kubia 是表示app=kubia的pod副本个数是replicas: 3 定义的个数。
```

### 1.5 创建service
```shell
# 创建service
[root@master example_yaml]# k expose rc kubia --type=NodePort --name kubia-http
service/kubia-http exposed
[root@master example_yaml]# k get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
kubernetes   ClusterIP   192.168.0.1      <none>        443/TCP          42h
kubia-http   NodePort    192.168.29.187   <none>        8080:30656/TCP   4s

# 端口映射
# k port-forward kubia 8080:30656 &
```

### 1.6 测试
```shell
[root@master ~]# curl http://192.168.101.100:30656
You've hit kubia-nrxc6
[root@master ~]# curl http://192.168.101.100:30656
You've hit kubia-n6szd
[root@master ~]# curl http://192.168.101.100:30656
You've hit kubia-rxdr9

```

### 1.7 水平伸缩应用
```shell
# 查看现在rc副本数
[root@master ~]# k get rc
NAME    DESIRED   CURRENT   READY   AGE
kubia   3         3         3       142m

# 现在想增加到5个
[root@master ~]# k scale rc kubia --replicas=5
replicationcontroller/kubia scaled
[root@master ~]# k get rc
NAME    DESIRED   CURRENT   READY   AGE
kubia   5         5         5       143m
[root@master ~]# k get pod
NAME             READY   STATUS             RESTARTS   AGE
fortune-config   1/2     CrashLoopBackOff   237        23h
kubia-jr6kv      1/1     Running            0          6s
kubia-lwc8p      1/1     Running            0          6s
kubia-n6szd      1/1     Running            0          143m
kubia-nrxc6      1/1     Running            0          143m
kubia-rxdr9      1/1     Running            0          143m
private-pod      1/1     Running            2          21h

# 现在想缩减到1个
[root@master ~]# k scale rc kubia --replicas=1
replicationcontroller/kubia scaled
[root@master ~]# k get rc
NAME    DESIRED   CURRENT   READY   AGE
kubia   1         1         1       143m
[root@master ~]# k get pod
NAME             READY   STATUS        RESTARTS   AGE
fortune-config   1/2     Error         238        23h
kubia-jr6kv      1/1     Terminating   0          35s
kubia-lwc8p      1/1     Terminating   0          35s
kubia-n6szd      1/1     Running       0          143m
kubia-nrxc6      1/1     Terminating   0          143m
kubia-rxdr9      1/1     Terminating   0          143m
private-pod      1/1     Running       2          21h
```

### 1.8 查看应用运行在那个node上
```shell
[root@master ~]# k get pod -o wide
NAME             READY   STATUS             RESTARTS   AGE    IP              NODE     NOMINATED NODE   READINESS GATES
fortune-config   1/2     CrashLoopBackOff   239        23h    172.173.55.17   node01   <none>           <none>
kubia-n6szd      1/1     Running            0          151m   172.173.55.22   node01   <none>           <none>
private-pod      1/1     Running            2          21h    172.173.55.15   node01   <none>           <none>

[root@master ~]# k describe pod kubia-n6szd 
Name:         kubia-n6szd
Namespace:    default
Priority:     0
Node:         node01/192.168.101.201
Start Time:   Fri, 24 Sep 2021 19:35:06 +0800
Labels:       app=kubia
Annotations:  <none>
Status:       Running
IP:           172.173.55.22
IPs:
  IP:           172.173.55.22
Controlled By:  ReplicationController/kubia
Containers:
  kubia:
...

```


## 2. kubectl 命令行tab补全
```shell
yum install bash-completion -y
source /usr/share/bash-completion/bash_completion

vim /root/.bashrc

alias k=kubectl
source <(kubectl completion bash | sed s/kubectl/k/g)
```
