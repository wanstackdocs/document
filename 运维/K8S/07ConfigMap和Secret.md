[toc]

# 07. ConfigMap和Secret

概述:
传递配置选项给运行在K8s上的应用程序。


## 7.1 向容器传递命令行参数

### 7.1.1 再Docker中定义命令与参数
`Dockerfile`中定义定义命令和参数的指令
    - `ENTRYPOINT`: 定义容器启动时被调用的可执行程序
    - `CMD`: 指定镜像运行时想要运行的命令，也可以指定 传递给 `ENTRYPOINT` 的参数

举例:

```shell
# 通过参数可配置化fortune脚本中的循环间隔
[root@k8s-master01 fortune]# cat fortuneloop.sh
#!/bin/bash
trap "exit" SIGINT
INTERVAL=$1
echo Configured to generate new fortune every $INTERVAL seconds
mkdir /var/htdocs -p
while :
do 
  echo $(date) Writing fortune to /var/htdocs/index.html
  /usr/games/fortune > /var/htdocs/index.html
  sleep $INTERVAL
done
```

```shell
[root@k8s-master01 fortune]# cat sources.list 
deb http://mirrors.163.com/ubuntu/ bionic main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ bionic-security main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ bionic-updates main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ bionic main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ bionic-backports main restricted universe multiverse
```

```shell
# 采用exec形式的ENTRYPOINT指令，以及利用CMD设置间隔的默认值为10
[root@k8s-master01 fortune]# cat Dockerfile 
FROM ubuntu:18.04
ADD sources.list /etc/apt/
RUN apt-get update; apt-get install fortune -y
ADD fortuneloop.sh /bin/fortuneloop.sh
ENTRYPOINT ["/bin/fortuneloop.sh"]
CMD ["10"]
```


```shell
# 构建镜像，并推送到docker hub中
docker build -t docker.io/wanstack/fortune:args .
docker push docker.io/wanstack/fortune:args
# 在本地启动该镜像并进行测试
docker run -it docker.io/wanstack/fortune:args
# 可以传递参数到docker 容器中
docker run -it docker.io/wanstack/fortune:args 15
```

### 7.1.2 在kubernetes中覆盖命令与参数

在kubernetes中定义容器时，镜像的`ENTRYPOINT` 和 `CMD` 都可以被覆盖，仅需要在容器定义中设置属性`command`和`args`的值，如下面的清单:
```yml
kind: Pod
spec:
  containers:
  - image: some/image
  command: ["/bin/command"l
  args: ["argl", "arg2", "arg3"]
```
在pod中传递参数值：fortune-pod-args.yaml
```yml
apiVersion: v1
kind: Pod
metadata:
  name: fortune2
spec:
  containers:
  - image: wanstack/fortune:args
    args: ["2"]  # 该参数值，使得脚本每个2秒生成一个新的fortune
    name: html-generator
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
  volumes:
  - name: html
    emptyDir: {}
```
```shell
k apply -f fortune-pod-args.yaml
```

```yml
args: # 参数比较多的情况下可以使用如下方式。数组，字符串值不需要引号，数值表示字符串需要引号
- foo
- bar
- "15"
```


## 7.2 为容器设置环境变量
环境变量被设置在pod的容器定义中，并非是pod级别

举例:

```shell
# 通过环境变量可配置化fortune脚本中的循环间隔
[root@k8s-master01 fortune]# cat fortuneloop.sh
#!/bin/bash
trap "exit" SIGINT
# INTERVAL=$1 相较于参数传递变量，这里不需要初始化
echo Configured to generate new fortune every $INTERVAL seconds
mkdir /var/htdocs -p
while :
do 
  echo $(date) Writing fortune to /var/htdocs/index.html
  /usr/games/fortune > /var/htdocs/index.html
  sleep $INTERVAL
done
```

```shell
[root@k8s-master01 fortune]# cat sources.list 
deb http://mirrors.163.com/ubuntu/ bionic main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ bionic-security main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ bionic-updates main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ bionic main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ bionic-backports main restricted universe multiverse
```

```shell
# 采用exec形式的ENTRYPOINT指令，以及利用CMD设置间隔的默认值为10
[root@k8s-master01 fortune]# cat Dockerfile 
FROM ubuntu:18.04
ENV INTERVAL=5 # 定义环境变量
ADD sources.list /etc/apt/
RUN apt-get update; apt-get install fortune -y
ADD fortuneloop.sh /bin/fortuneloop.sh
ENTRYPOINT ["/bin/fortuneloop.sh", "$INTERVAL"] # 引用环境变量
```


```shell
# 构建镜像，并推送到docker hub中
docker build -t docker.io/wanstack/fortune:env .
docker push docker.io/wanstack/fortune:env
# 在本地启动该镜像并进行测试
docker run -it docker.io/wanstack/fortune:env
```

### 7.2.1 在pod的容器中指定环境变量
在pod中指定环境变量: fortune-pod-env.yaml
```yml
apiVersion: v1
kind: Pod
metadata:
  name: fortune3
spec:
  containers:
  - image: wanstack/fortune:env
    env:
    - name: INTERVAL # 在环境变量中添加一个新的环境变量，环境变量是配置在pod的容器中，非pod级别
      value: "2"
    name: html-generator
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
  volumes:
  - name: html
    emptyDir: {}
```

```shell
k apply -f fortune-pod-env.yaml
k logs -f fortune3
```


### 7.2.3 在环境变量中引用其他的环境变量

```yml
env:
- name: FIRST_VAR  # 定义第一个环境变量
  value: "foo"
- name: SECOND_VAR # 定义第二个环境变量
  value: "$(FIRST_VAR)bar"  # 通过$(FIRST_VAR)引用第一个环境变量。此时 SECOND_VAR的值是 "foobar"
```

## 7.3 利用ConfigMap解耦配置

### 7.3.1 ConfigMap介绍
不管是参数传递还是环境变量，虽然应用程序和配置文件独立出来，但是还是强耦合。
如果多套环境，比如开发环境、测试环境、生产环境。配置文件和应用都是强耦合在一起的。

ConfigMap可以将配置存放在独立的资源对象中，这有助于在不同环境（开发、测试、质量保障和生产等）下拥有多份同名配置清单（通过命名空间加以区分）。pod是通过名称引用 ConfigMap 的，因此可以在多环境下使用相同的 pod 定义描述，同时保持不同的配置值 以适应不同环境。


### 7.3.2 创建ConfigMap
```shell
# 通过kubectl 命令创建 configmap
# 创建一个名为fortune-config 的ConfigMap, 仅包含单映射条目 sleep-interval=25
kubectl create configmap fortune-config --from-literal=sleep-interval=25
# 可以创建多条映射条目
kubectl create configmap myconfigmap --from-literal=foo=bar --from-literal=bar=baz --from-literal=one=two

# 查看configmap的yaml描述信息
[root@k8s-master01 ~]# k get configmaps fortune-config -o yaml
apiVersion: v1
data:
  sleep-interval: "25"   # 映射中的唯一条目
kind: ConfigMap  # 描述符定义了一个configmap
metadata:
  creationTimestamp: "2021-09-03T11:29:00Z"
  name: fortune-config  # 映射的名称（通过这个名称引用ConfigMap）
  namespace: default
  resourceVersion: "5150533"
  uid: 2b5cb7c7-4791-4825-ae2e-b8035bc7e0d4

[root@k8s-master01 ~]# k get configmaps myconfigmap -o yaml
apiVersion: v1
data:
  bar: baz
  foo: bar
  one: two
kind: ConfigMap
metadata:
  creationTimestamp: "2021-09-09T17:26:31Z"
  name: myconfigmap
  namespace: default
  resourceVersion: "6159123"
  uid: 4042f250-0f16-4996-ad6c-acd6d835a4ef
```
使用yaml文件创建ConfigMap
fortune-config.yml
```yml
apiVersion: v1
data:
  sleep-interval: "25"
kind: ConfigMap
metadata:
  name: fortune-config
  namespace: default
```

从文件内容创建ConfigMap条目
```shell
# 从磁盘上读取文件，并将文件内容单独存储为ConfigMap 中的条目 
# kubectl 会在当前目录下查找 config-file.conf 文件，并将文件内容存储在 ConfigMap中以config-file.conf为键名的条目下
k create configmap my-config --from-file=config-file.conf
# 可以手工指定键名
k create configmap my-config --from-file=customkey=config-file.conf
# 这条命令会将文件内容存在键名为customkey的条目下。与使用字面量时相同，多次使用 --from-file 参数可增加多个文件条目
```
从文件夹创建ConfigMap条目
```shell
# 除单独引入每个文件外，甚至可以引入某一文件夹中的所有文件
kubectl create configmap my -config --from-file=/path/to/dir
# 这种情况下， kubectl 会为文件夹中的每个文件单独创建条目，仅限于那些文件名可作为合法 ConfigMap 键名的文件 
```
混合文件和文件夹创建ConfigMap条目
```shell
# 创建 ConfigMap 时可 以混合使用上述提到的所有选项
k create configmap my-config --from-file=foo.json --from-file=bar=foobar.conf --from-file=config-opts/ --from-literal=some=thing
```

### 7.3.3 给容器传递ConfigMap条目作为环境变量（1）
```yml
# 定义一个环境变量 INTERVAL, 并将其值设置为fortune-config ConfigMap 中键名是sleep-interval对应的值
# 运行在html-generator 容器中的进程读取到环境变量INTERVAL 的值为25
[root@k8s-master01 configmap]# cat fortune-pod-env-configmap.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: fortune-env-from-configmap
spec:
  containers:
  - image: wanstack/fortune:env
    env:
    - name: INTERVAL # 在环境变量中添加一个新的环境变量，环境变量是配置在pod的容器中，非pod级别
      valueFrom:
        configMapKeyRef:
          name: fortune-config
          key: sleep-interval
    name: html-generator
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
  volumes:
  - name: html
    emptyDir: {}
```

### 7.3.4 一次传递ConfigMap 的所有条目作为环境变量
```shell
[root@k8s-master01 config_env]# cat fortuneloop.sh 
#!/bin/bash
trap "exit" SIGINT
while :
do 
  echo CONFIG_FOO $CONFIG_FOO
  echo CONFIG_BAR $CONFIG_BAR
  echo CONFIG_FOO-BAR $CONFIG_FOO-BAR
  sleep 3
done
[root@k8s-master01 config_env]# cat Dockerfile 
FROM ubuntu:18.04
ENV CONFIG_FOO: "FOO"
ENV CONFIG_BAR: "BAR"
ENV CONFIG_FOO-BAR: "FOO-BAR"
ADD fortuneloop.sh /bin/fortuneloop.sh
ENTRYPOINT ["/bin/fortuneloop.sh", "CONFIG_FOO", "CONFIG_BAR", "CONFIG_FOO-BAR"]


# 打包成镜像
docker build -t docker.io/wanstack/fortune:three .
# 上传到hub.docker.com上
docker push docker.io/wanstack/fortune:three
```

```yml
[root@k8s-master01 configmap]# cat config-three.yml 
apiVersion: v1
data:
  CONFIG_FOO: "TEXT1"
  CONFIG_BAR: "TEST2"
  CONFIG_FOO-BAR: "TEXT3"
kind: ConfigMap
metadata:
  name: my-config-map
  namespace: default

```
config-pod-three.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-three
spec:
  containers:
  - image: wanstack/fortune:three
    envFrom:
    - prefix: CONFIG_
      configMapRef:
        name: my-config-map
    name: html-generator
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
  volumes:
  - name: html
    emptyDir: {}

```

### 7.3.4 传递ConfigMap条目作为命令行参数
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-env-from-configmap
spec:
  containers:
  - image: wanstack/fortune:env
    env:
    - name: INTERVAL # 在环境变量中添加一个新的环境变量，环境变量是配置在pod的容器中，非pod级别
      valueFrom:
        configMapKeyRef:
          name: fortune-config
          key: sleep-interval
    name: html-generator
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
  volumes:
  - name: html
    emptyDir: {}
```
## 7.4 使用Secret传递敏感数据

## 7.5 本章小结
