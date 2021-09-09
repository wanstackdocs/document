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
不管是参数传递还是环境变量，虽然应用程序和配置文件独立出来，但是还是强耦合。
如果多套环境，比如开发环境、测试环境、生产环境。配置文件和应用都是强耦合在一起的。




## 7.4 使用Secret传递敏感数据

## 7.5 本章小结
