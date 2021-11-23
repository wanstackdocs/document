## 1. with 介绍

with 语句适用于对资源进行访问的场合，确保不管使用过程中是否发生异常都会执行必要的“清理”操作，释放资源，比如文件使用后自动关闭／线程中锁的自动获取和释放等。

问题引出
如下代码：
```python
file = open("１.txt")
data = file.read()
file.close()
```

上面代码存在２个问题：
（１）文件读取发生异常，但没有进行任何处理；
（２）可能忘记关闭文件句柄；

改进
```python
try:
    f = open('xxx')
except:
    print('fail to open')
    exit(-1)
try:
    do something
except:
    do something
finally:
    f.close()
```

虽然这段代码运行良好，但比较冗长。而使用with的话，能够减少冗长，还能自动处理上下文环境产生的异常。如下面代码：
```python
with open("１.txt") as file:
    data = file.read()
```

with 工作原理
（１）紧跟with后面的语句被求值后，返回对象的“__enter__()”方法被调用，这个方法的返回值将被赋值给as后面的变量；
（２）当with后面的代码块全部被执行完之后，将调用前面返回对象的“__exit__()”方法。

with工作原理代码示例：
```python
class Sample:
    def __enter__(self): # 第二步
        print "in __enter__"
        return "Foo"
    def __exit__(self, exc_type, exc_val, exc_tb): # 第四步
        print "in __exit__"
def get_sample():
    return Sample()
with get_sample() as sample:  # 第一步
    print "Sample: ", sample  # 第三步
```   
# 结果如下：
in __enter__
Sample:  Foo
in __exit__

可以看到，整个运行过程如下：
（１）enter()方法被执行；
（２）enter()方法的返回值，在这个例子中是”Foo”，赋值给变量sample；
（３）执行代码块，打印sample变量的值为”Foo”；
（４）exit()方法被调用；

【注】exit()方法中有３个参数， exc_type, exc_val, exc_tb，这些参数在异常处理中相当有用。
  exc_type：　错误的类型
  exc_val：　错误类型对应的值
  exc_tb：　代码中错误发生的位置
  示例代码：
```python
class Sample():
    def __enter__(self):
        print('in enter')
        return self
    def __exit__(self, exc_type, exc_val, exc_tb):
        print "type: ", exc_type
        print "val: ", exc_val
        print "tb: ", exc_tb
    def do_something(self):
        bar = 1 / 0
        return bar + 10
with Sample() as sample:
    sample.do_something()
```  
# 程序输出结果：
```python
in enter
Traceback (most recent call last):
type:  <type 'exceptions.ZeroDivisionError'>
val:  integer division or modulo by zero
  File "/home/user/cltdevelop/Code/TF_Practice_2017_06_06/with_test.py", line 36, in <module>
tb:  <traceback object at 0x7f9e13fc6050>
    sample.do_something()
  File "/home/user/cltdevelop/Code/TF_Practice_2017_06_06/with_test.py", line 32, in do_something
    bar = 1 / 0
ZeroDivisionError: integer division or modulo by zero

Process finished with exit code 1
```
总结
实际上，在with后面的代码块抛出异常时，exit()方法被执行。开发库时，清理资源，关闭文件等操作，都可以放在exit()方法中。总之，with-as表达式极大的简化了每次写finally的工作，这对代码的优雅性是有极大帮助的。如果有多项，可以这样写：
With open('1.txt') as f1, open('2.txt') as  f2:
    do something


```python
from svcloud.common import log as logging
LOG = logging.getLogger()


class TaskManager(object):
    def __init__(self, rollback_on_error=True, raise_error=True):
        self.rollback_on_error = rollback_on_error
        self.raise_error = raise_error
        self.rollback_tasks = []

    def add_rollback_task(self, func, *args, **kwargs):
        self.rollback_tasks.append((func, args, kwargs))

    def rollback(self):
        while self.rollback_tasks:
            rollback_func, args, kwargs = self.rollback_tasks.pop()
            if not rollback_func:
                print(f"No Rollback function defined")
                continue
            try:
                rollback_func(*args, **kwargs)
            except Exception as e:
                LOG.error(e)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        error = exc_tb is not None
        if error and self.rollback_on_error:
            self.rollback()
        return not self.raise_error
```

使用:

```python
with TaskManager() as tm: # tm是 __enter__ 返回值，执行 vm=xxx
    vm = self.call("create_vm", **kwargs)
    # 下面执行只要报错，就会执行 tm.__exit__方法
    tm.add_rollback_task(self.get_func("delete_vm"), vm.get("id")) 
    # 创建接入方式
    networks = vm.get("networks")
    request_user = vm.get("request_user")
    for network in networks:
        access_modes = network.get("access_modes")
        if not access_modes:
            continue
    ... 
```