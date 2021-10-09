[toc]

# 1. pod: 运行于kubernetes中的容器

内容概要:
1. 创建、启动和停止pod
2. 使用标签组织pod和其他资源
3. 使用特定标签对所有pod执行操作
4. 使用命名空间将多个pod分到不重叠的组中
5. 调度pod到指定类型的工作节点

## 1.1 pod
pod是k8s基本构建模块，一个pod可以包含多个容器，其中每个容器仅运行一个应用进程。

由于不能将多个进程聚集在一个单独的容器中，我们需要另 一种更高级的结构来将容器绑定在一起，并将它们作为一个单元进行管理，这就是 pod 背后的根本原理。

1. 同一个pod中容器之间的部分隔离
k8s通过配置docker来让同一个pod内的所有容器共享相同的namespace，共享相同的主机名、网络接口、IPC(Inter-Process Communication，进程间通信)。新版本k8s和docker中，也可以共享PID，但是该特征未激活。

>注意:当同一个 pod 中的容器使用单独的 PID 命名空间时，在容器中执行 psaux 就只会看到容器自己的进程

由于一个pod 中的容器运行于相同的 Network 命名空间中，因此它们共享相同的 IP 地址和端口空间。 这意味着在同一 pod 中的容器运行的多个进程需要注意不能绑定到相同的端口号， 否则会导致端口冲突， 但这只涉及同-pod 中的容器。 由千每个 pod 都有独立的端口空间， 对于不同 pod 中的容器来说则永远不会遇到端口冲突。 此外， 一个 pod 中的所有容器也都具有相同的 loopback网络接口，因此容器可以通过 localhost 与同一 pod 中的其他容器进行通信。

2. 通过pod合理管理容器
一个pod只能运行在一个工作节点上。
举例： 前端和后端是否应该运行在同一个pod？不应该
>1. 充分利用多个工作节点的CPU，假如只有一个pod，包含2个容器，前端和后端。这样就无法利用多个工作节点的CPU资源。
>2. 基于扩缩容考虑而分割多个pod中，pod是扩缩容基本单位，不能横向扩展pod中的单个容器，只能扩缩容pod。前端和后端扩缩容有不同的需求，所以需要分割成2个pod。

什么情况下可以组合多个容器在一个pod中？
- 如果有一个主进程容器和多个辅助进程容器可以组合成一个pod。
> 例如，有一个web容器对外提供服务，另外一个容器定时从外部下载资源到web容器对应的目录中。


## 1.2 以yaml或者json描述文件创建pod

1. pod定义主要部分
- metadata: 包含名称，命名空间，标签和关于容器的其他信息
- spec: 包含pod内容的实际说明，例如pod的容器，卷和其他数据。
- status: 包含运行中的pod的当前信息，例如pod所处的条件，每个容器的描述和状态，以及内部IP和其他基本信息。


2. 创建pod的yaml描述文件
现在创建一个名为kubia-manual.yaml 的文件
```yaml
apiVersion: v1   # 为什么是v1，怎么查看版本，后面会有介绍
kind: Pod        # 资源类型是pod
metadata:
  name: kubia-manual  # pod的名称, 注意我这里统一按照2个空格缩进
spec:
  containers:
  - image: wanstack/kubia  # 创建容器所用的镜像
    name: kubia     # 容器名称
    ports:
    - containerPort: 8080  # 应用容器监听的端口，这里仅仅是描述监听的端口，实际上不描述也是监听的80端口，和应用有关系
      protocol: TCP
```
```shell
# 现在来看一下为什么是v1
[root@master ~]# k explain pod
KIND:     Pod
VERSION:  v1

DESCRIPTION:
     Pod is a collection of containers that can run on a host. This resource is
     created by clients and scheduled onto hosts.

FIELDS:
   apiVersion	<string>
     APIVersion defines the versioned schema of this representation of an
     object. Servers should convert recognized schemas to the latest internal
     value, and may reject unrecognized values. More info:
     https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources

   kind	<string>
     Kind is a string value representing the REST resource this object
     represents. Servers may infer this from the endpoint the client submits
     requests to. Cannot be updated. In CamelCase. More info:
     https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds

   metadata	<Object>
     Standard objects metadata. More info:
     https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata

   spec	<Object>
     Specification of the desired behavior of the pod. More info:
     https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

   status	<Object>
     Most recently observed status of the pod. This data may not be up to date.
     Populated by the system. Read-only. More info:
     https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

You have new mail in /var/spool/mail/root
[root@master ~]# k explain pod.apiVersion
KIND:     Pod
VERSION:  v1  # 这里写的是v1

FIELD:    apiVersion <string>

DESCRIPTION:
     APIVersion defines the versioned schema of this representation of an
     object. Servers should convert recognized schemas to the latest internal
     value, and may reject unrecognized values. More info:
     https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources

```

3. 创建pod
```shell
# 创建
k create -f kubia-manual.yaml

# 得到pod的完成定义
k get pod -o yaml # 可以是yaml
k get pod -o json # 可以是json

# 查看pod中容器的日志，如果一个pod只有一个容器可以直接查看pod日志，如果多个则需要精确到容器
[root@master 03]# k logs kubia-manual 
Kubia server starting...
[root@master 03]# k logs kubia-manual -c kubia   # 其中-c 表示pod中的容器
Kubia server starting...
```

4. 向pod发送请求
```shell
# 将本地的8888端口转发至pod的80端口
k port-forward kubia-manual 8888:8080 &

# 测试
[root@master 03]# curl localhost:8888
Handling connection for 8888
You've hit kubia-manual

```
```shell
         8888                                    8080
curl <---------> kubectl port-forward process <---------> pod kubia-manual

```


## 1.3 使用标签组织pod
标签是附加到k8s资源上的任意键值对，可以通过标签选择器选择确切标签的资源。只要标签的key是唯一，一个资源可以拥有多个标签，一般创建资源是就会在资源上附加上标签，之后也可以增加其他标签，或者修改现有标签中的值。

1. 给pod打标签
- app: 这个标签可以表示pod属于哪个应用、组件或者微服务
- rel: 显示pod中应用程序的版本是stable、beta、还是cannary

>全丝雀发布是指在部署新版本时， 先只让一 小部分用户体验新版本以观察新版本的表现， 然后再向所有用户进行推广， 这样可以防止暴露有问题的版本给过多的用户。
[03pod.drawio]

## 1.4 创建pod时指定标签
vim kubia-manual-with-labels.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-manual-v2
  labels:
    creation_method: manual  # 2个标签被附加到pod上
    env: prod
spec:
  containers:
  - image: wanstack/kubia
    name: kubia
    ports:
    - containerPort: 8080
      protocol: TCP
```

```shell
k create -f kubia-manual-with-labels.yaml
[root@master 03]# k get pod --show-labels 
NAME              READY   STATUS    RESTARTS   AGE     LABELS
kubia-manual      1/1     Running   1          128m    <none>
kubia-manual-v2   1/1     Running   0          26s     creation_method=manual,env=prod
kubia-n6szd       1/1     Running   1          6h30m   app=kubia
private-pod       1/1     Running   3          25h     <none>


[root@master 03]# k get pod -L creation_method,env
NAME              READY   STATUS    RESTARTS   AGE     CREATION_METHOD   ENV
kubia-manual      1/1     Running   1          132m                      
kubia-manual-v2   1/1     Running   0          3m59s   manual            prod
kubia-n6szd       1/1     Running   1          6h34m                     
private-pod       1/1     Running   3          25h 
```

2. 修改现有pod
```shell
# 这个应该是新建标签
[root@master 03]# k label pod kubia-manual creation_method=manual
pod/kubia-manual labeled

# 修改原有标签，注意需要加上 --overwrite
[root@master 03]# k label pod kubia-manual-v2 env=debug --overwrite

```

## 1.5 通过标签选择器列出pod子集

标签选择器可以选择标记有特定标签的pod子集，并对这些pod进行操作。可以说，标签选择器是一种能够根据是否包含特定值的特定标签来过滤资源的准则。

标签选择器根据资源的以下条件来选择资源:
- 包含（或不包含）使用特定键的标签
- 包含具有特定键和值的标签
- 包含具有特定键的标签，但其值与我们指定的不同

1. 使用标签选择器列出pod

```shell
# 列出所有pod
[root@master ~]# k get pod --show-labels 
NAME              READY   STATUS    RESTARTS   AGE     LABELS
kubia-manual      1/1     Running   2          41h     creation_method=manual
kubia-manual-v2   1/1     Running   1          39h     creation_method=manual,env=debug
kubia-n6szd       1/1     Running   2          45h     app=kubia
private-pod       1/1     Running   4          2d16h   <none>
# 过滤出标签含有键是creation_method的pod，这里的建是精确匹配
[root@master ~]# k get pod -l creation_method
NAME              READY   STATUS    RESTARTS   AGE
kubia-manual      1/1     Running   2          41h
kubia-manual-v2   1/1     Running   1          39h

# 列出标签env=debug的所有pod
[root@master ~]# k get pod -l env=debug
NAME              READY   STATUS    RESTARTS   AGE
kubia-manual-v2   1/1     Running   1          39h

# 列出没有env标签的pod, 注意 单引号
[root@master ~]# k get pod -l '!env'
NAME           READY   STATUS    RESTARTS   AGE
kubia-manual   1/1     Running   2          2d
kubia-n6szd    1/1     Running   2          2d5h
private-pod    1/1     Running   4          3d
```

- creation_method!=manual 选择带有creation_method标签， 并且值不等于manual的pod
- env in (prod, devel)选择带有env标签且值为prod或devel的pod
- env notin (prod, devel)选择带有env标签， 但其 值不是prod或devel的pod

2. 在标签选择器中使用多个条件
```shell
k get pod -l app=pc,rel=beta  # 逗号表示且条件，都需要满足
```

## 1.6 使用标签选择器来约束pod调度

默认情况下，pod是随机分配到k8s的工作节点上，但是实际情况却是，工作节点不同的物理资源，我们想要把某些pod，调度到指定的某些工作节点上，可以通过标签来实现。

1. 使用标签分类工作节点
pod并不是唯一可以附加标签的k8s资源，标签可以附加到任何k8s资源上，包括节点。

比如向k8s集群中新加了一个工作节点，它的硬件资源有GPU，为了加以区分工作节点(可以对工作节点进行分类)
```shell
# 给node02 工作节点 打标签
k label node node02 gpu=true

# 列出标签gpu=true的工作节点
[root@master 03]# k get nodes -l gpu=true
NAME     STATUS   ROLES    AGE     VERSION
node02   Ready    <none>   5d20h   v1.21.5

# 列出所有node，并显示标签key为gpu值的列，和之前的pod类似
[root@master 03]# k get nodes -L gpu
NAME     STATUS   ROLES                  AGE     VERSION   GPU
master   Ready    control-plane,master   5d20h   v1.21.5   
node01   Ready    <none>                 5d20h   v1.21.5   
node02   Ready    <none>                 5d20h   v1.21.5   true
```

2. 将pod调度到特定节点

将pod调度到gpu=true 的工作节点上
vim kubia-gpu.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-gpu
spec:
  nodeSelector:  # 节点选择器: 要求k8s只将pod部署到包含标签gpu=true的节点上
    gpu: "true"
  containers:
  - image: wanstack/kubia
    name: kubia

```
```shell
k apply -f kubia-gpu.yaml

[root@master 03]# k get pod -o wide
NAME          READY   STATUS              RESTARTS   AGE     IP              NODE     NOMINATED NODE   READINESS GATES
kubia-gpu     0/1     ContainerCreating   0          12s     <none>          node02   <none>           <none>
kubia-n6szd   1/1     Running             4          4d2h    172.173.55.30   node01   <none>           <none>
private-pod   1/1     Running             6          4d21h   172.173.55.31   node01   <none>           <none>

```

3. 调度到一个特定节点
每个工作节点都会有一个 kubernetes.io/hostname: node02  的标签，键为: kubernetes.io/hostname，值为工作节点的主机名，因为可以将pod调度到某个确定的节点上，但是如果节点处于离线状态，通过这组标签将nodeSelector 设置为特定节点会导致pod不可调度。这是不明智的。正确的做法是给多个相似的工作节点打上标签，然后通过nodeSelector选择。


## 1.7 注解pod
pod和其他对象除了标签以外还可以包含注解，注解也是键值对，注解不同于标签，标签有标签选择器，注解则没有。
注解可以容纳更多的信息，向k8s引入新特性时可以使用注解，一般来说新功能的alpha和beta版本不会向API引入任何新字段，因为可以使用注解而不是字段，一旦所需的API更改变得清晰并且得到相关人员认可则会引入新字段并废弃相关注解。从这方面看注解可能时一个过度。注解也可以用于说明，比如指定创建对象的人员姓名。

1. 查找对象的注解
```shell
[root@master 03]# k get node -o yaml
apiVersion: v1
items:
- apiVersion: v1
  kind: Node
  metadata:
    annotations:
      kubeadm.alpha.kubernetes.io/cri-socket: /var/run/dockershim.sock
      node.alpha.kubernetes.io/ttl: "0"
      volumes.kubernetes.io/controller-managed-attach-detach: "true"
...

```

2. 添加和修改注解
注解可以在创建pod时添加，也可以在现有的pod中添加和修改。

```shell
# 在现有pod中添加注解
[root@master 03]# k annotate pod kubia-gpu mycompany.com/someannotate="foo far"
pod/kubia-gpu annotated

# 查看新添加的注解
[root@master 03]# k describe pod kubia-gpu 
Name:         kubia-gpu
Namespace:    default
Priority:     0
Node:         node02/192.168.101.202
Start Time:   Tue, 28 Sep 2021 22:24:22 +0800
Labels:       <none>
Annotations:  mycompany.com/someannotate: foo far
Status:       Running
...

```

## 1.8 使用命名空间对资源进行分组

首先可以使用命名空间对k8s资源进行分组，不同命名空间下可以存在相同资源名称。

1. 了解对命名空间的需求

在使用多个namespace的前提下，我们可以将包含大量组件的复杂系统拆分为不通的组，这些不同的组也可以用于在多租户环境下分配资源，将资源分配为生产、开发、QA环境。大部分资源都与namespace有关系，但是还有一些资源时和namespace无关的。比如 节点资源和一些集群级别的资源。

2. 发现其他命名空间及pod

```shell
# 列出所有的命名空间
[root@master 03]# k get ns
NAME              STATUS   AGE
default           Active   6d1h
ingress-nginx     Active   5d5h
kube-node-lease   Active   6d1h
kube-public       Active   6d1h
kube-system       Active   6d1h

# 默认不指定命名空间则显示时default命名空间下的资源 -A 表示显示所有命名空间下的资源

# 列出 kube-system命名空间下的所有资源 
[root@master 03]# k get pod -n kube-system 
NAME                                      READY   STATUS    RESTARTS   AGE
calico-kube-controllers-cdd5755b9-dm2cv   1/1     Running   5          5d
calico-node-8mczc                         1/1     Running   6          6d
calico-node-qzgvz                         1/1     Running   8          6d
calico-node-r4nvp                         1/1     Running   7          6d
coredns-6f6b8cc4f6-v4t56                  1/1     Running   7          6d
coredns-6f6b8cc4f6-wrlht                  1/1     Running   5          5d
etcd-master                               1/1     Running   7          6d1h
kube-apiserver-master                     1/1     Running   10         6d1h
kube-controller-manager-master            1/1     Running   13         6d1h
kube-proxy-528xg                          1/1     Running   7          6d1h
kube-proxy-qlsrj                          1/1     Running   7          6d1h
kube-proxy-xl8nh                          1/1     Running   5          6d1h
kube-scheduler-master                     1/1     Running   16         6d1h
 
# 如果有多个用户使用同一个k8s集群，可以使用各自的命名空间，这样一来就不需要担心资源名称冲突问题。命名空间为资源提供了一个作用域。
```


3. 创建一个命名空间

命名空间是一种和其他资源一样的k8s资源，因此可以通过将 YAML 文件提交到 k8s API服务器来创建。

从YAML 文件创建命名空间
vim custom-namespace.yaml
```yaml
apiVersion: v1
kind: Namespace           # 资源类型为命名空间
metadata:
  name: custom-namespace  # 命名空间名称  
```
```shell
[root@master 03]# k apply -f custom-namespace.yaml 
namespace/custom-namespace created
[root@master 03]# 
[root@master 03]# 
[root@master 03]# k get ns
NAME               STATUS   AGE
custom-namespace   Active   4s
default            Active   6d1h
ingress-nginx      Active   5d5h
kube-node-lease    Active   6d1h
kube-public        Active   6d1h
kube-system        Active   6d1h
```

从命令行创建命名空间
```shell
[root@master 03]# k create namespace test
namespace/test created
[root@master 03]# k get ns
NAME               STATUS   AGE
custom-namespace   Active   84s
default            Active   6d1h
ingress-nginx      Active   5d5h
kube-node-lease    Active   6d1h
kube-public        Active   6d1h
kube-system        Active   6d1h
test               Active   4s
```

4. 管理其他命名空间中的对象

YAML 文件中可以在metadata字段中添加 namespace: custom-namespace 属性。
命令行: 
```shell
[root@master 03]# k create -f kubia-manual.yaml -n custom-namespace
pod/kubia-manual created
[root@master 03]# k apply -f kubia-manual.yaml 
pod/kubia-manual created
[root@master 03]# k get pod
NAME           READY   STATUS              RESTARTS   AGE
kubia-gpu      1/1     Running             0          5h5m
kubia-manual   0/1     ContainerCreating   0          2s
kubia-n6szd    1/1     Running             4          4d7h
private-pod    1/1     Running             6          5d2h
[root@master 03]# k get pod -n custom-namespace 
NAME           READY   STATUS    RESTARTS   AGE
kubia-manual   1/1     Running   0          21s
# 此时，我们有2个同名的pod，一个在default命名空间中，一个在custom-namespace命名空间中
```


切换命名空间
```shell
# 在列出、描述、修改和删除其他命名空间中的对象时，需要 -n 指定命名空间。
# 如果不指定命名空间，k8s则在当前默认的命名空间中执行操作。

# 查看当前上下文信息
[root@master 03]# k config get-contexts 
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin   default
[root@master 03]# k config current-context
kubernetes-admin@kubernetes

# 切换命名空间
kcd=$(k config set-context $(k config current-context) --namespace)
# 切换到custom-namespace命名空间下
kcd custom-namespace  

```


5. 命名空间提供的隔离
实际上命名空间的隔离，只是部分隔离。比如想要隔离2个pod进行通信，需要k8s提供响应的网络方案，而不是依靠k8s中的民命空间。

## 1.9 停止和移除pod

1. 按照名称移除pod
```shell
k delete pod kubia-gpu 

# 在删除pod的过程中，实际上我们在指示k8s终止pod中的所有容器，k8s向进程发送一个SIGTERM信号，并等待一定的描述(默认30s)，使其正常关闭。如果没有及时关闭，则通过SIGKILL终止该进程。因此为了保证进程总是正常关闭，进程需要正确处理SIGTERM信号。
```

2. 使用标签选择器删除pod

```shell
[root@master 03]# k get pod --show-labels 
NAME          READY   STATUS    RESTARTS   AGE     LABELS
kubia-2t4k2   1/1     Running   0          5s      app=kubia
kubia-n6szd   1/1     Running   4          4d21h   app=as
private-pod   1/1     Running   6          5d16h   <none>

# 根据标签删除pod
[root@master 03]# k delete pod -l app
pod "kubia-2t4k2" deleted
pod "kubia-n6szd" deleted

# 之前的金丝雀发布中，可以一次性删除所有金丝雀的pod
k delete pod -l rel=canary
```


3. 通过删除整个命名空间来删除pod
```shell
# 删除命名空间, 命名空间中的pod会伴随命名空间自动删除
k delete ns custom-namespace
```

4. 删除所有命名空间中的pod，但是保留命名空间

```shell
# 删除命名空间中的所有pod --all 参数
k delete pod --all

# 由RC创建的pod，会重新创建新的pod，除非删除RC，否则只要删除pod，RC控制器都会创建新的pod
```


5. 删除命名空间中(几乎)所有资源

```shell
# 删除命名空间(几乎所有的资源),包括pod和RC控制器, service也会被删除
[root@master 03]# k delete all --all  # all 表示所有的资源类型，--all 表示所有的资源示例
pod "kubia-mpr8p" deleted
replicationcontroller "kubia" deleted
service "kubernetes" deleted
service "kubia-http" deleted
```