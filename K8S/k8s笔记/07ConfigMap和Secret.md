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
环境变量的定义与之前相同，但是需要通过$(ENV_VARIABLE_NAME)将环境变量的值注入到参数变量的值
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
    args: ["$(INTERVAL)"] # 在参数设置中引用环境变量
    name: html-generator
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
  volumes:
  - name: html
    emptyDir: {}
```

### 7.3.5 使用configMap 卷将条目暴露为文件
创建文件夹configmap-files ，并在configmap-files中创建my-nginx-config.conf文件
开启gzip压缩的Nginx配置文件 configmap-files/my-nginx-config.conf
```shell
server {
  listen      80;
  server_name  www.kubia-example.com;
  gzip        on;
  gzip_types  text/plain application/xml;
  location / {
    root  /usr/share/nginx/html;
    index index.html index.hml;
  }

}
```
在configmap-files中创建sleep-interval 文件,内容为 25
```shell
25
```

从文件夹创建configmap
```shell
k create configmap fortune-config --from-file=configmap-files
```

从文件夹创建configmap的yaml格式定义，configmap包含2个条目，条目的键名和文件名相同。
```yaml
[root@k8s-master01 configmap]# k get configmaps fortune-config -o yaml
apiVersion: v1
data:
  my-nginx-config.conf: |  # 这里的 | 管道符表示后续的条目值是多行字面量
    server {
      listen      80;
      server_name  www.kubia-example.com;
      gzip        on;
      gzip_types  text/plain application/xml;
      location / {
        root  /usr/share/nginx/html;
        index index.html index.hml;
      }

    }
  sleep-interval: |
    25
kind: ConfigMap
metadata:
  creationTimestamp: "2021-09-13T11:12:26Z"
  name: fortune-config
  namespace: default
  resourceVersion: "6764239"
  uid: 450a813b-ec7d-4142-8f70-25e08725e1dd
```
使用上面的configmap创建pod
创建包含configmap条目内容的卷，只需要创建一个引用configmap名称的卷并挂载到容器中。
pod 挂载configmap条目作为文件: fortune-pod-configmap-volume.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-configmap-volume
spec:
  containers:
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: config
      mountPath: /etc/nginx/conf.d # 挂载configmap卷至这个位置
      readOnly: true
    ports:
    - containerPort: 80
      protocol: TCP
  volumes:
  - name: config
    configMap:
      name: fortune-config # 卷定义引用fortune-config

```
检查nginx是否使用被挂载的配置文件。
现在的web服务器应该已经被配置为会压缩响应，可以将本地的8080端口转发到pod的80端口，使用curl进行测试。
```shell
 k port-forward fortune-configmap-volume 8080:80 &
 [root@k8s-master01 configmap]# curl -H "Accept-Encoding: gzip" -I localhost:8080
Handling connection for 8080
HTTP/1.1 200 OK
Server: nginx/1.21.3
Date: Mon, 13 Sep 2021 11:46:28 GMT
Content-Type: text/html
Last-Modified: Tue, 07 Sep 2021 15:50:58 GMT
Connection: keep-alive
ETag: W/"61378a62-267"
Content-Encoding: gzip # 这里响应说明已经被压缩了

```
检查被挂载的configmap卷内容
```shell
[root@k8s-master01 configmap]# k exec fortune-configmap-volume -c web-server -- ls /etc/nginx/conf.d
my-nginx-config.conf
sleep-interval
```
这里sleep-interval 不是给nginx使用的，但是确实被包含进来了。怎么办呢？可以指定暴露的configmap条目

#### 7.3.5.1 卷内暴露指定configmap条目
将 my-nginx-config.conf 暴露为configmap卷中的文件，sleep-interval作为环境变量

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-config
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
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: config
      mountPath: /etc/nginx/conf.d
      readOnly: true
    ports:
    - containerPort: 80
      protocol: TCP
  volumes:
  - name: config
    configMap:
      name: fortune-config
      items:  # 选择包含在卷中的条目
      - key: my-nginx-config.conf  # 该键对应的条目被包含
        path: gzip.conf # 条目的值被存在在该文件中
  - name: html
    emptyDir: {}
```
挂载某一文件夹会隐藏该文件夹中已存在的文件，比如上面的例子会隐藏原本/etc/nginx/conf.d/ 文件夹下的所有文件。

configmap独立条目作为文件被挂载，且不隐藏文件夹中的其他文件。
假设拥有一个包含文件myconfig.conf的configMap卷(可能是一个文件夹)，希望能将其添加为/etc文件夹下的文件someconfig.conf。通过属性subPath可以将该文件挂载的同时又不影响文件夹中的其他文件。具体示例如下:
```yaml
spec:
  containers:
  - image: some/image
    volumeMounts:
    - name: myvolume
      mountPath: /etc/someconfig.conf  # 挂载至某一个文件，而不是文件夹
      subPath: myconfig.conf  # 仅挂载指定条目，而不是完整的卷
```

#### 7.3.5.2 为configmap卷中的文件设定权限
r 读权限read  4
w 写权限write 2
x 操作权限execute  1

configmap卷中的文件默认被设置为644 (-rw-r-r--),可以通过卷规格定义中的defaultMode属性改变默认权限。
```yaml
valumes:
- name: config
  configMap:
    name: fortune-config
    defaultMode: "6600" 
```
```shell
文件权限除了r、w、x外还有s、t、i、a权限：

s：文件属主和组设置SUID和GUID，文件在被设置了s权限后将以root身份执行。在设置s权限时文件属主、属组必须先设置相应的x权限，否则s权限并不能正真生效（chmod 命令不进行必要的完整性检查，即使不设置x权限就设置s权限，chmod也不会报错，当我们ls -l时看到rwS，大写S说明s权限未生效）。Linux修改密码的passwd便是个设置了SUID的程序，普通用户无读写/etc/shadow文件的权限确可以修改自己的密码。

ls -al /usr/bin/passwd
-rwsr-xr-x 1 root root 32988 2008-12-08 17:17 /usr/bin/passwd

我们可以通过字符模式设置s权限：chmod a+s filename，也可以使用绝对模式进行设置：

设置s u i d：将相应的权限位之前的那一位设置为4；
设置g u i d：将相应的权限位之前的那一位设置为2；
两者都置位：将相应的权限位之前的那一位设置为4+2=6。

如：chmod 4764 filename   //设置SUID

t ：设置粘着位，一个文件可读写的用户并一定相让他有删除此文件的权限，如果文件设置了t权限则只用属主和root有删除文件的权限，通过chmod +t filename 来设置t权限。

i：不可修改权限  例：chattr u+i filename 则filename文件就不可修改，无论任何人，如果需要修改需要先删除i权限，用chattr -i filename就可以了。查看文件是否设置了i权限用lsattr filename。

a：只追加权限， 对于日志系统很好用，这个权限让目标文件只能追加，不能删除，而且不能通过编辑器追加。可以使用chattr +a设置追加权限。
```


### 7.3.6 更新应用配置且不重启应用程序
使用环境变量或者命令行参数作为配置源的弊端在于无法在进程运行时更新配置。 
将ConfigMap暴露为卷可以达到配置热更新的效果， 无须重新创建pod或者重启容器。
ConfigMap被更新之后， 卷中引用它的所有文件也会相应更新， 进程发现文件被改变之后进行重载。 
Kubemetes同样支待文件更新之后手动通知容器。

注意点: 
1. configmap文件更新时间较长可能需要1分钟
2. configmap仅仅是对配置文件进行更新，如果想要程序应用需要程序进行重载配置文件，比如nginx -s reload操作。

举例：
kubectl edit 命令修改ConfigMap fortune-config 来关闭gzip压缩。
kubectl edit configmap fortune-config
将 gzip  on; 修改为 gzip  off; 
重载nginx配置
kubectl exec fortune-config -c web-server -- nginx -s reload

## 7.4 使用Secret给容器传递敏感数据

  1. 将Secret条目作为环境变量传递给容器
  2. 将Secret条目暴露为卷中的文件

Kubemetes 通过仅仅将 Secret 分发到需要访问 Secret 的 pod 所在的机器节点来保障其安全性。 另外， Secret 只会存储在节点的内存中， 永不写入物理存储， 这样从节点上删除 Secret 时就不需要擦除磁盘了
  1. 采用 ConfigMap 存储非敏感的文本配置数据。
  2. 采用 Secret 存储天生敏感的数据， 通过键来引用。 如果一 个配置文件同时包含敏感与非敏感数据， 该文件应该被存储在 Secret 中。

### 7.4.1 创建Secret
创建私钥和证书，使nginx可以服务于https流量。
```shell
# 创建证书和私钥
[root@master secret]# openssl genrsa -out https.key 2048
[root@master secret]# openssl req -new -x509 -key https.key -out https.cert -days 3650 -subj /CN=www.kubia-example.com
# 创建一个内容为bar的文件foo
echo bar > foo

# 创建secret，这里是引用文件，也可以引用目录
k create secret generic fortune-https --from-file=https.key --from-file=https.cert --from-file=foo 
```

### 7.4.2 对比Secret和ConfigMap
```shell
[root@master secret]# k get secrets fortune-https -o yaml
apiVersion: v1
data:
  foo: YmFyCg==
  https.cert: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURFekNDQWZ1Z0F3SUJBZ0lKQUlRRnQ2SWRPLzhETUEwR0NTcUdTSWIzRFFFQkN3VUFNQ0F4SGpBY0JnTlYKQkFNTUZYZDNkeTVyZFdKcFlTMWxlR0Z0Y0d4bExtTnZiVEFlRncweU1UQTVNak14TkRVMk5UTmFGdzB6TVRBNQpNakV4TkRVMk5UTmFNQ0F4SGpBY0JnTlZCQU1NRlhkM2R5NXJkV0pwWVMxbGVHRnRjR3hsTG1OdmJUQ0NBU0l3CkRRWUpLb1pJaHZjTkFRRUJCUUFEZ2dFUEFEQ0NBUW9DZ2dFQkFMUGkveU9KVmFpd2QyLzFmR0ZGS0NwbFlvalkKTjdIRmd4S1ZMSkdubDJlQ1NCR0tvbGxHWUZUcVFxNVVBQlUvampvd1BJR05ubHpaVWRzc01CUHA2Y2xia0Z4SwpVUDl6N3pITEtLSEpnRktyTVByUEpVTzc5V3RPMVFJQS9Qb1JOVzcrV1FGdHkxcVVWTHBHSStDd2JHWTFRVVc3CjFUOHlTbEQxNDNvbDRqUFd4eWVoZWdyejJrcXlBUVZkV2IxTFU2bzJKVXNueXAyRk1QMmRvdExMRUptOUtBcEQKZVY2dC9uejlhc3RJUGh3U0NRa08rMWNPVVdyNW1kbWJnOGY3R2orQjUxUmZSQnRoSnFFNHZIVVR4QWRxWXVwMgpKMkpCVlNibmx4WU9uN2l5R0x1cEMweUN2a2o1bnhNTnIyaXZlV1MwMjIrMkRabjlXQmtaKzVEM3FjTUNBd0VBCkFhTlFNRTR3SFFZRFZSME9CQllFRkxyK1BiR1h6OUVWODREZHMwdldzbjNJTWg4T01COEdBMVVkSXdRWU1CYUEKRkxyK1BiR1h6OUVWODREZHMwdldzbjNJTWg4T01Bd0dBMVVkRXdRRk1BTUJBZjh3RFFZSktvWklodmNOQVFFTApCUUFEZ2dFQkFEZTU4NlZtaVV5bkVTeFVJYWFwbG11OWxmTy83MUxLSnArZUdRbjQzeFhRZFY5Z0NObXVoRU53CnZqaW13MnFMVllLU25oRjF0alNyTWZZT3FkMlJOTlEzUkdaWjh4WEtsRk5yQWZBYnJ4YWE1VVA1cFhCbURXN2MKNSthTG10azhoRlNzWWt5aHROV05nT0U0WWRoVm9OY2FIYk9kNFhSalhCZU5GSmVTaDlPdVJxc0ZHdkdWMGJYNAo2UDdoam1pQ1kxM3hLNEZEWWxURklZWEphbTdObTI4QjdYTDB5akN5UlNRL20rVURmeGtNWmZEUEJKWHk5dVIrCnV1U1FZWFlwdlNudzZNOWdQcXAzV0ZpL0Y5S0Z1aGRqeWxSSTF6Mk9mNFdhajJPVlgxLytHdjF5SUY2QXZpcE0KQmdaTzVQYm5lZTVGc29zenRRWkZoZzFkb2doc2gwOD0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  https.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBcytML0k0bFZxTEIzYi9WOFlVVW9LbVZpaU5nM3NjV0RFcFVza2FlWFo0SklFWXFpCldVWmdWT3BDcmxRQUZUK09PakE4Z1kyZVhObFIyeXd3RStucHlWdVFYRXBRLzNQdk1jc29vY21BVXFzdytzOGwKUTd2MWEwN1ZBZ0Q4K2hFMWJ2NVpBVzNMV3BSVXVrWWo0TEJzWmpWQlJidlZQekpLVVBYamVpWGlNOWJISjZGNgpDdlBhU3JJQkJWMVp2VXRUcWpZbFN5ZktuWVV3L1oyaTBzc1FtYjBvQ2tONVhxMytmUDFxeTBnK0hCSUpDUTc3ClZ3NVJhdm1aMlp1RHgvc2FQNEhuVkY5RUcyRW1vVGk4ZFJQRUIycGk2blluWWtGVkp1ZVhGZzZmdUxJWXU2a0wKVElLK1NQbWZFdzJ2YUs5NVpMVGJiN1lObWYxWUdSbjdrUGVwd3dJREFRQUJBb0lCQUJwamZHWXNLV0s3c0dtKwpLMmJoakVqYjRwNk1pVzhNdUhPcmFvUmJmM3h4d2p6QWg1eHRGSWlnYlBQQjR0azdINVF0cTFLZUFkTkJGaDcrCjFuYTFZOVJrR0VOUnE1d3QxN01JU0llalZhM0s2ejUvME1tazh4V3cxTktjYm9BSXNqdjhGL1o3c3M4dzMxVU0KSVFzL0ZrZlFIQ2tzcXRYQWZPSnZqOVZGWlcrUkhXUGRXMTdSdStNTVpEUHpzV0xUZWF4WWFHTW9KaDhxM0Y1Qwo3SEZTKzhNd2dRMitxSDFiZlpKTjNEaXNUZWl6REpGUEsxNnptQjFnalVBVmFET3RuaU5aQ20zTWwvQS9PcG1XCkQreEMrcHdqMXM3Z1k5MEl5c05zd0pzSW5lYmtMSWFSalRuVEJNQWxVcW5WTmNPMUs0Q1ZOamk1SGhDN0h5MU4KaVVROHFSRUNnWUVBMTNBTXpuL1Y2bk5uMFZqbFF5QmJRdng2VmM5K2pDbEc1YkpIRFNwUzNScFN1RUViZ0crZApPNy9ab0h6ZWQwNlhiVnJWSkRtVU5mbGdtS0lMZDh2aVVhV0sycTkwOTB1R0lhcFhiTEt0b0lyNkpSUXE1ak1uClpPNUVTcEwxc1dTQWNWWnNPQW55a3F2RDR4WDFWd3I3QmlOak5tbmtkTXpzRnA2bmlBZGp4eFVDZ1lFQTFjRnAKeERJMExjOUxSWEkxelhxcjRuVWU1bGRoTlUvek4wc2s0TmsydUpRN1RJWWRhK21VcG5jdFR4eWE2b0t1dGpFOQo3RUxXTjcvNDVza0tKNHJUcWFKWkdWbVZvV211R2pFU0tQc0orNnlmZEQ3TmpUSDFyVGhIS204bHIvckdrbi9kCkJoVWhLNVZGMldpRDRReUVzMjlRRkN0R2F6ZmQzZE5kZEJOMVkzY0NnWUJ6ejNveTc2bHcxUVQwRnROM21FYzIKNVQ1bUxwcWFnZjNvc0VOZG9talZEcmQwOFJyMW1ncHQraDNsRmZzSks2aGZVcnJOTkY2bC9SNmVMazMzNGhRUgpTK291MEs4UjJQbUwwMlFYdkoxMWRnQXVPbjh0TEVaN0RWS012Qjl6Y3RGUkcrSWs1Y1FPY0dObkNZRFBmOG1kCmJSeUNQYjVmdzJFT2I4OGpZc1dTV1FLQmdRREd1RFBheVEySFZRTFdRaEpRdisyUjcyNVZtQUJ3THE2ZXhnWTMKM3Rnbml1OEIrbURaMU9KMFM3RmNyZXc3Zmxoc1dxVUZ3ekVoelIvWmRpY3hrYmVyS1pvSm5pWWtWSG9lTVdaLwpvTHFzTmRSYm5wTTc0NmxSYTFPRjJLVEIwTExRdVh4Q1RseHpCeWhUc1AyQnVFQ2FEQzczUVRBTE4zblU0czRyCnZuZFFpd0tCZ1FDam45UjY0OC9ReEJWWWJNUHFXNWlzbEtNVnJnTGZkekxaL1dYZm41V1NrdFJZVmVGVXRxN1kKa1FzanlZeEpWR0hYeGduMExobTdNQUJ6TVRKdnJISzNpYnA5UkN2U1ROdlVYK2x0OE1CaWo0eVZTbUxTVXJxTQpUZ2xmdlJhSWRnN0E3WUJYRzl6bUZqNzNldDhGRjJYaGtYczVkWHFEYWZlazl2ajNvUGdkZGc9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
kind: Secret
metadata:
  creationTimestamp: "2021-09-23T14:58:54Z"
  name: fortune-https
  namespace: default
  resourceVersion: "36566"
  uid: ab146304-dacf-4748-9ce9-c3085b9fd163
type: Opaque

[root@master secret]# k get configmaps fortune-config -o yaml
apiVersion: v1
data:
  my-nginx-config.conf: |
    server {
      listen      80;
      server_name  www.kubia-example.com;
      gzip        on;
      gzip_types  text/plain application/xml;
      location / {
        root  /usr/share/nginx/html;
        index index.html index.hml;
      }

    }
  sleep-interval: |
    25
kind: ConfigMap
metadata:
  creationTimestamp: "2021-09-23T14:42:19Z"
  name: fortune-config
  namespace: default
  resourceVersion: "35604"
  uid: 482b815d-858f-451c-8972-a8936a3cd73e

```
Secret 条目的内容会被以 Base64格式编码，而ConfigMap直接以纯文本展示。这种区别导致在处理YAML和JSON格式的Secret时会稍许有些麻烦，需要在设置和读取相关条目时对内容进行编解码。

采用Base64编码的原因很简单。Secret的条目可以涵盖二进制数据，而不仅仅是纯文本。Base64编码可以将二进制数据转换为纯文本，以YAML 或JSON格式展示。

stringData字段：
由于并非所有的敏感数 据都是二进 制形 式，Kubemetes允许通过Secret的stringData字段设置条目的纯文本值，如下面的代码清单所示
```yaml
kind: Secret
apiVersion: v1
stringData:
  foo: bar
data:
  https.cert: xxx
  https.key: xxx
```

stringData字段是只写的（注意：是只写，非只 读），可以被用来设置条目值。通过kubectl ge七-o yaml获取Secret的YAML格式定义时，不会显示 stringData字段。 相反，stringData字段中的所有条目（如上面示例中的foo条目） 会被Base64编码之后展示在data字段下。

### 7.4.3 在pod中使用Secret
```shell
# 修改fortune-config configmap开启https
k edit configmaps fortune-config 

apiVersion: v1
data:
  my-nginx-config.conf: |
    server {
      listen      80;
      listen      443 ssl;
      server_name  www.kubia-example.com;
      ssl_certificate   certs/https.cert;
      ssl_certificate_key certs/https.key;
      ssl_protocols     TLSv1 TLSv1.1 TLSv1.2;
      ssl_ciphers       HIGH:!aNULL:!MD5;
      gzip        on;
      gzip_types  text/plain application/xml;
      location / {
        root  /usr/share/nginx/html;
        index index.html index.hml;
      }

    }
  sleep-interval: |
    25

上面配置了服务器从／etc/nginx/ceris 中读取证书与密钥文件，因此之后 需要将secret 卷挂载于此。

# 创建pod，并将fortune-https 挂载到pod上
vim fotune-pod-https.yaml


apiVersion: v1
kind: Pod
metadata:
  name: fortune-https
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
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
      readOnly: true
    - name: config
      mountPath: /etc/nginx/conf.d
      readOnly: true
    - name: certs
      mountPath: /etc/nginx/certs  # 配置Nginx从/etc/nginx/certs 中读取证书和密钥文件，需要将secret挂载于此
      readOnly: true
    ports:
    - containerPort: 80
    - containerPort: 443
  volumes:
  - name: config
    configMap:
      name: fortune-config
      items:  # 选择包含在卷中的条目
      - key: my-nginx-config.conf  # 该键对应的条目被包含
        path: gzip.conf # 条目的值被存在在该文件中
  - name: html
    emptyDir: {}
  - name: certs
    secret:
      secretName: fortune-https  # 这里引用fortune-https secret来定义secret卷


k apply -f fortune-pod-https.yaml

# 测试nginx是否使用secret中的证书和密钥
# 开启端口转发
kubectl port-forward fortune-https 8443:443 &

# 使用curl进行测试
curl https://localhost:8443 -k -v
* About to connect() to localhost port 8443 (#0)
*   Trying ::1...
* Connected to localhost (::1) port 8443 (#0)
* Initializing NSS with certpath: sql:/etc/pki/nssdb
Handling connection for 8443
* skipping SSL peer certificate verification
* SSL connection using TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
* Server certificate:
* 	subject: CN=www.kubia-example.com
* 	start date: Sep 23 14:56:53 2021 GMT
* 	expire date: Sep 21 14:56:53 2031 GMT
* 	common name: www.kubia-example.com
* 	issuer: CN=www.kubia-example.com
> GET / HTTP/1.1
> User-Agent: curl/7.29.0
> Host: localhost:8443
> Accept: */*
> 
< HTTP/1.1 200 OK
< Server: nginx/1.21.3
< Date: Thu, 23 Sep 2021 15:55:13 GMT
< Content-Type: text/html
< Content-Length: 35
< Last-Modified: Thu, 23 Sep 2021 15:55:10 GMT
< Connection: keep-alive
< ETag: "614ca35e-23"
< Accept-Ranges: bytes
< 
Your aim is high and to the right.
* Connection #0 to host localhost left intact

```

### 7.4.4 Secret 卷存储与内存
通过挂载secret卷至文件夹/etc/nginx/certs 将证书和私钥成功传递给容器。secret卷采用内存文件系统列出容器的挂载点。
```shell
[root@master secret]# k exec -ti fortune-https -c web-server -- mount | grep certs
tmpfs on /etc/nginx/certs type tmpfs (ro,relatime)
```
由于使用的是tmpfs，存储在secret中的数据不会写入磁盘。

### 7.4.5 通过环境变量暴露secret条目
```yaml
env:
- name: FOO_SECRET # 通过secret条目设置环境变量
  valueFrom:  
    secretKeyRef:
      name: fortune-https  # secret 键
      key: foo # secret 的名称
```


### 7.4.6 docker私有仓库上传和拉取

上传：
在docker hub上创建私有仓库
修改本地tag：
docker tag e65db7680f9d wanstack/private:env  # 其中wanstack/private 是私有仓库
docker push wanstack/private:env # 上传至docker创建的私有仓库

在pod中拉取私有镜像：
创建用于docker镜像仓库鉴权的secret
k create secret docker-registry mydockerhubsecret --docker-username=wanstack --docker-password='xxx!@#' --docker-email=xxx@139.com

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-pod
spec:  
  imagePullSecrets:  # 字段 imagePullSecrets 引用了 mydockerhubsecret Secret
  - name: mydockerhubsecret
  containers:
  - image: wanstack/private:env
    name: main

```
k apply -f private-pod.yaml
假设某系统中通常运行大量 pod，你可能会好奇是否需要为每个 pod 都添加相同的镜像拉取 Secret。幸运的是，情况并非如此。第12章中将会学习到如何通过添加Secret至ServiceAccount使所有pod 都能 自动添加上镜像拉取Secret。