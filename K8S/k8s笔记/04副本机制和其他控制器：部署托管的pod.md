[toc]

## 1. 保持pod健康

使用RC或者DaemonSet控制器创建pod的好处:
当pod所在的工作节点失败后，pod容器可以在其他节点上重新被控制器创建，直接创建pod没有这个功能。


### 1.1 介绍存活探针




### 1.2 创建基于HTTP的存活探针

### 1.3 使用存活探针

### 1.4 配置存活探针的附加属性

### 1.5 创建有效的存活探针


## 2. ReplicationController控制器



## 3. RelicaSet代替ReplicationController



## 4. DaemonSet在每个节点上运行一个pod



## 5. 运行执行单个任务的pod



## 6. 安排Job定期运行或在将来运行一次