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
         8888                                    8080
curl <---------> kubectl port-forward process <---------> pod kubia-manual


